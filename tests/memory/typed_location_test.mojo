from std.testing import assert_equal, assert_false, assert_true
from tsonic_runtime import (
    Location,
    LocationIdentity,
    TypedLocation,
    bind_location,
    access_location,
    project_location,
    project_optional_location,
    equal_typed_location,
    hash_typed_location,
)
from tsonic_runtime import (
    RaisingCallable,
    ErasedCallableContext,
    allocate_callable_environment,
    destroy_callable_environment,
)


@fieldwise_init
struct Access:
    var cell: Location[Int32]

    @staticmethod
    def read(
        context: ErasedCallableContext, var _arguments: Tuple[]
    ) raises -> Int32:
        return context.unsafe_bitcast[Self]()[].cell.read()

    @staticmethod
    def write(
        context: ErasedCallableContext, var arguments: Tuple[Int32]
    ) raises:
        if arguments[0] < 0:
            raise Error("negative store")
        context.unsafe_bitcast[Self]()[].cell.write(arguments[0])

    @staticmethod
    def increment(
        _context: ErasedCallableContext, var arguments: Tuple[Int32]
    ) raises -> Int32:
        return arguments[0] + 1

    @staticmethod
    def decrement(
        _context: ErasedCallableContext, var arguments: Tuple[Int32]
    ) raises -> Int32:
        return arguments[0] - 1


def retained() -> TypedLocation[Int32]:
    var owner = Location[Int32](3)
    var state = allocate_callable_environment(
        Access(owner), destroy_callable_environment[Access]
    )
    return bind_location(
        owner,
        LocationIdentity(UInt(Int(owner._storage.unsafe_ptr())), ""),
        RaisingCallable[Tuple[], Int32](state, Access.read),
        RaisingCallable[Tuple[Int32], NoneType](state, Access.write),
    )


def read_cell(cell: Location[Int32], offset: Int32) raises -> Int32:
    return cell.read() + offset


def write_cell(
    mut cell: Location[Int32], offset: Int32, var value: Int32
) raises:
    cell.write(value - offset)


def retained_accessor(cell: Location[Int32]) -> TypedLocation[Int32]:
    return access_location(
        cell,
        Int32(2),
        LocationIdentity(UInt(Int(cell._storage.unsafe_ptr())), ""),
        read_cell,
        write_cell,
    )


@fieldwise_init
struct MoveOnly(Movable):
    var text: String


def read_owned(cell: Location[MoveOnly], key: Int) raises -> MoveOnly:
    assert_equal(key, 0)
    return MoveOnly(cell.borrow().text)


def write_owned(
    mut cell: Location[MoveOnly], key: Int, var value: MoveOnly
) raises:
    assert_equal(key, 0)
    cell.write(value^)


def main() raises:
    var cell = Location[Int32](1)
    var first = TypedLocation[Int32](cell)
    var second = TypedLocation[Int32](cell)
    var independent = TypedLocation[Int32](Int32(1))
    second.write(4)
    assert_equal(cell.read(), 4)
    assert_true(equal_typed_location[Int32](first, second))
    assert_false(equal_typed_location[Int32](first, independent))
    assert_equal(
        hash_typed_location[Int32](first), hash_typed_location[Int32](second)
    )
    assert_equal(hash_typed_location[Int32](None), 0.0)
    assert_true(equal_typed_location[Int32](None, None))
    var pointer = retained()
    var shared = pointer
    shared.write(8)
    assert_equal(pointer.read(), 8)
    var rejected = False
    try:
        shared.write(-1)
    except error:
        assert_equal(String(error), "negative store")
        rejected = True
    assert_true(rejected)
    assert_equal(pointer.read(), 8)
    var environment = allocate_callable_environment(
        Access(cell), destroy_callable_environment[Access]
    )
    var forward = RaisingCallable[Tuple[Int32], Int32](
        environment, Access.increment
    )
    var backward = RaisingCallable[Tuple[Int32], Int32](
        environment, Access.decrement
    )
    var shifted = project_location(pointer, forward, backward)
    assert_equal(shifted.read(), 9)
    shifted.write(12)
    assert_equal(pointer.read(), 11)
    assert_true(equal_typed_location[Int32](pointer, shifted))
    assert_equal(
        hash_typed_location[Int32](pointer), hash_typed_location[Int32](shifted)
    )
    assert_false(
        Bool(project_optional_location[Int32, Int32](None, forward, backward))
    )
    assert_false(
        pointer.identity.member("left") == pointer.identity.member("right")
    )
    assert_false(pointer.identity.member("1") == pointer.identity.index(1))
    var accessor = retained_accessor(cell)
    accessor.write(17)
    assert_equal(cell.read(), 15)
    assert_equal(accessor.read(), 17)
    assert_true(equal_typed_location[Int32](accessor, first))
    var escaped_accessor = retained_accessor(Location[Int32](5))
    assert_equal(escaped_accessor.read(), 7)
    escaped_accessor.write(10)
    assert_equal(escaped_accessor.read(), 10)
    var owned = Location(MoveOnly("original"))
    var move_only = access_location(
        owned,
        0,
        LocationIdentity(UInt(Int(owned._storage.unsafe_ptr())), ""),
        read_owned,
        write_owned,
    )
    move_only.write(MoveOnly("transferred"))
    assert_equal(owned.borrow().text, "transferred")

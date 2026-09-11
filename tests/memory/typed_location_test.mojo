from std.testing import assert_equal, assert_false, assert_true
from tsonic_runtime import (
    Location,
    LocationIdentity,
    TypedLocation,
    bind_location,
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
        LocationIdentity(UInt(Int(owner._storage.ptr())), ""),
        RaisingCallable[Tuple[], Int32](state, Access.read),
        RaisingCallable[Tuple[Int32], NoneType](state, Access.write),
    )


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

from std.utils import Variant
from .location import Location
from .location_identity import LocationIdentity
from .native_location import NativeLocation
from .raw_pointer import RawPointer
from std.sys import size_of
from .callable import (
    RaisingCallable,
    ErasedCallableContext,
    allocate_callable_environment,
    destroy_callable_environment,
)


@fieldwise_init
struct _LocationAccessors[T: Movable & Deinitable](ImplicitlyCopyable):
    var read: RaisingCallable[Tuple[], Self.T]
    var write: RaisingCallable[Tuple[Self.T], NoneType]


struct TypedLocation[T: Movable & Deinitable](ImplicitlyCopyable):
    var _storage: Variant[
        Location[Self.T], _LocationAccessors[Self.T], NativeLocation[Self.T]
    ]
    var identity: LocationIdentity

    def __init__(out self, var value: Self.T):
        var cell = Location[Self.T](value^)
        self.identity = LocationIdentity(UInt(Int(cell._storage.ptr())), "")
        self._storage = cell

    def __init__(out self, cell: Location[Self.T]):
        self.identity = LocationIdentity(UInt(Int(cell._storage.ptr())), "")
        self._storage = cell

    def __init__(
        out self,
        identity: LocationIdentity,
        read: RaisingCallable[Tuple[], Self.T],
        write: RaisingCallable[Tuple[Self.T], NoneType],
    ):
        self.identity = identity
        self._storage = _LocationAccessors[Self.T](read, write)

    def __init__(out self, var native: NativeLocation[Self.T]):
        self.identity = LocationIdentity(native.address._address, "")
        self._storage = native^

    def read(self) raises -> Self.T where conforms_to(Self.T, Copyable):
        if self._storage.isa[Location[Self.T]]():
            return self._storage.unsafe_get[Location[Self.T]]().read()
        if self._storage.isa[NativeLocation[Self.T]]():
            return self._storage.unsafe_get[NativeLocation[Self.T]]().read()
        return self._storage.unsafe_get[_LocationAccessors[Self.T]]().read.call(
            ()
        )

    def write(mut self, var value: Self.T) raises:
        if self._storage.isa[Location[Self.T]]():
            var cell = self._storage.unsafe_get[Location[Self.T]]()
            cell.write(value^)
        elif self._storage.isa[NativeLocation[Self.T]]():
            var native = self._storage.unsafe_get[NativeLocation[Self.T]]()
            native.write(value^)
        else:
            self._storage.unsafe_get[_LocationAccessors[Self.T]]().write.call(
                (value^,)
            )

    def same_storage(self, other: Self) -> Bool:
        return self.identity == other.identity

    def to_raw(self) raises -> Optional[RawPointer]:
        if self._storage.isa[NativeLocation[Self.T]]():
            return self._storage.unsafe_get[
                NativeLocation[Self.T]
            ]().address.copy()
        if self._storage.isa[Location[Self.T]]():
            var cell = self._storage.unsafe_get[Location[Self.T]]()
            return RawPointer.retained(
                cell._storage,
                UInt(Int(cell._storage.ptr())),
                UInt(size_of[Self.T]()),
            )
        return None


@fieldwise_init
struct _BoundLocation[Owner: Movable & Deinitable, T: Movable & Deinitable]:
    var owner: Self.Owner
    var read: RaisingCallable[Tuple[], Self.T]
    var write: RaisingCallable[Tuple[Self.T], NoneType]

    @staticmethod
    def load(
        context: ErasedCallableContext, var _arguments: Tuple[]
    ) raises -> Self.T:
        return context.unsafe_bitcast[Self]()[].read.call(())

    @staticmethod
    def store(
        context: ErasedCallableContext, var arguments: Tuple[Self.T]
    ) raises:
        context.unsafe_bitcast[Self]()[].write.call(arguments^)


def bind_location[
    Owner: Movable & Deinitable, T: Movable & Deinitable
](
    var owner: Owner,
    identity: LocationIdentity,
    read: RaisingCallable[Tuple[], T],
    write: RaisingCallable[Tuple[T], NoneType],
) -> TypedLocation[T]:
    comptime Environment = _BoundLocation[Owner, T]
    var environment = allocate_callable_environment(
        Environment(owner^, read, write),
        destroy_callable_environment[Environment],
    )
    return TypedLocation[T](
        identity,
        RaisingCallable[Tuple[], T](environment, Environment.load),
        RaisingCallable[Tuple[T], NoneType](environment, Environment.store),
    )


@fieldwise_init
struct _ProjectedLocation[
    Source: Copyable & Deinitable, Target: Movable & Deinitable
]:
    var pointer: TypedLocation[Self.Source]
    var from_source: RaisingCallable[Tuple[Self.Source], Self.Target]
    var to_source: RaisingCallable[Tuple[Self.Target], Self.Source]

    @staticmethod
    def load(
        context: ErasedCallableContext, var _arguments: Tuple[]
    ) raises -> Self.Target:
        var projection = context.unsafe_bitcast[Self]()
        return projection[].from_source.call((projection[].pointer.read(),))

    @staticmethod
    def store(
        context: ErasedCallableContext, var arguments: Tuple[Self.Target]
    ) raises:
        var projection = context.unsafe_bitcast[Self]()
        var value = projection[].to_source.call(arguments^)
        projection[].pointer.write(value^)


def project_location[
    Source: Copyable & Deinitable, Target: Movable & Deinitable
](
    pointer: TypedLocation[Source],
    from_source: RaisingCallable[Tuple[Source], Target],
    to_source: RaisingCallable[Tuple[Target], Source],
) -> TypedLocation[Target]:
    comptime Environment = _ProjectedLocation[Source, Target]
    var environment = allocate_callable_environment(
        Environment(pointer, from_source, to_source),
        destroy_callable_environment[Environment],
    )
    return TypedLocation[Target](
        pointer.identity,
        RaisingCallable[Tuple[], Target](environment, Environment.load),
        RaisingCallable[Tuple[Target], NoneType](
            environment, Environment.store
        ),
    )


def project_optional_location[
    Source: Copyable & Deinitable, Target: Movable & Deinitable
](
    pointer: Optional[TypedLocation[Source]],
    from_source: RaisingCallable[Tuple[Source], Target],
    to_source: RaisingCallable[Tuple[Target], Source],
) -> Optional[TypedLocation[Target]]:
    if not pointer:
        return None
    return project_location(pointer.value(), from_source, to_source)


def equal_typed_location[
    T: Movable & Deinitable
](left: Optional[TypedLocation[T]], right: Optional[TypedLocation[T]]) -> Bool:
    if left:
        return right and left.value().same_storage(right.value())
    return not right


def hash_typed_location[
    T: Movable & Deinitable
](pointer: Optional[TypedLocation[T]]) -> Float64:
    return pointer.value().identity.hash() if pointer else 0.0

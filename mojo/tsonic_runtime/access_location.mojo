from .callable import (
    ErasedCallableContext,
    RaisingCallable,
    allocate_callable_environment,
    destroy_callable_environment,
)
from .location_identity import LocationIdentity
from .typed_location import TypedLocation


@fieldwise_init
struct _AccessLocation[
    Owner: Movable & Deinitable,
    Key: Copyable & Deinitable,
    Value: Movable & Deinitable,
]:
    var owner: Self.Owner
    var key: Self.Key
    var read: def(Self.Owner, Self.Key) raises -> Self.Value
    var write: def(mut Self.Owner, Self.Key, var Self.Value) raises -> NoneType

    @staticmethod
    def load(
        context: ErasedCallableContext, var _arguments: Tuple[]
    ) raises -> Self.Value:
        var access = context.unsafe_bitcast[Self]()
        return access[].read(access[].owner, access[].key)

    @staticmethod
    def store(
        context: ErasedCallableContext, var arguments: Tuple[Self.Value]
    ) raises:
        var access = context.unsafe_bitcast[Self]()
        access[].write(access[].owner, access[].key, arguments[0]^)


def access_location[
    Owner: Movable & Deinitable,
    Key: Copyable & Deinitable,
    Value: Movable & Deinitable,
](
    var owner: Owner,
    key: Key,
    identity: LocationIdentity,
    read: def(Owner, Key) raises -> Value,
    write: def(mut Owner, Key, var Value) raises -> NoneType,
) -> TypedLocation[Value]:
    comptime Environment = _AccessLocation[Owner, Key, Value]
    var environment = allocate_callable_environment(
        Environment(owner^, key.copy(), read, write),
        destroy_callable_environment[Environment],
    )
    return TypedLocation[Value](
        identity,
        RaisingCallable[Tuple[], Value](environment, Environment.load),
        RaisingCallable[Tuple[Value], NoneType](environment, Environment.store),
    )

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
    var reader: def(Self.Owner, Self.Key) thin raises -> Self.Value
    var writer: def(
        mut Self.Owner, Self.Key, var Self.Value
    ) thin raises -> NoneType

    @staticmethod
    def load(
        context: ErasedCallableContext, var _arguments: Tuple[]
    ) raises -> Self.Value:
        var access = context.unsafe_bitcast[Self]()
        return access[].reader(access[].owner, access[].key)

    @staticmethod
    def store(
        context: ErasedCallableContext, var arguments: Tuple[Self.Value]
    ) raises:
        var access = context.unsafe_bitcast[Self]()
        var selected = Optional[Self.Value]()

        @parameter
        def take[index: Int](var value: Self.Value):
            selected = rebind_var[Self.Value](value^)

        arguments^.consume_elements[take]()
        access[].writer(access[].owner, access[].key, selected.take())


def access_location[
    Owner: Movable & Deinitable,
    Key: Copyable & Deinitable,
    Value: Movable & Deinitable,
](
    var owner: Owner,
    key: Key,
    identity: LocationIdentity,
    reader: def(Owner, Key) thin raises -> Value,
    writer: def(mut Owner, Key, var Value) thin raises -> NoneType,
) -> TypedLocation[Value]:
    comptime Environment = _AccessLocation[Owner, Key, Value]
    var environment = allocate_callable_environment(
        Environment(owner^, key.copy(), reader, writer),
        destroy_callable_environment[Environment],
    )
    return TypedLocation[Value](
        identity,
        RaisingCallable[Tuple[], Value](environment, Environment.load),
        RaisingCallable[Tuple[Value], NoneType](environment, Environment.store),
    )

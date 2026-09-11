from .callable import (
    Callable,
    RaisingCallable,
    ErasedCallableContext,
    allocate_callable_environment,
    destroy_callable_environment,
)


@fieldwise_init
struct _CallableResult[
    Arguments: Movable & Deinitable, Source: Movable, Target: Movable
]:
    var callable: Callable[Self.Arguments, Self.Source]
    var convert: def(var Self.Source) thin -> Self.Target

    @staticmethod
    def invoke(
        context: ErasedCallableContext, var arguments: Self.Arguments
    ) -> Self.Target:
        var adapter = context.unsafe_bitcast[Self]()
        var result = adapter[].callable.call(arguments^)
        return adapter[].convert(result^)


@fieldwise_init
struct _RaisingCallableResult[
    Arguments: Movable & Deinitable,
    Source: Movable,
    Target: Movable,
    ErrorType: AnyType,
]:
    var callable: RaisingCallable[Self.Arguments, Self.Source, Self.ErrorType]
    var convert: def(var Self.Source) thin -> Self.Target

    @staticmethod
    def invoke(
        context: ErasedCallableContext, var arguments: Self.Arguments
    ) raises Self.ErrorType -> Self.Target:
        var adapter = context.unsafe_bitcast[Self]()
        var result = adapter[].callable.call(arguments^)
        return adapter[].convert(result^)


def adapt_callable_result[
    Arguments: Movable & Deinitable, Source: Movable, Target: Movable
](
    value: Callable[Arguments, Source],
    convert: def(var Source) thin -> Target,
) -> Callable[Arguments, Target]:
    comptime Adapter = _CallableResult[Arguments, Source, Target]
    var environment = allocate_callable_environment(
        Adapter(value, convert), destroy_callable_environment[Adapter]
    )
    return Callable[Arguments, Target](
        environment, Adapter.invoke, value.identity()
    )


def adapt_raising_callable_result[
    Arguments: Movable & Deinitable,
    Source: Movable,
    Target: Movable,
    ErrorType: AnyType,
](
    value: RaisingCallable[Arguments, Source, ErrorType],
    convert: def(var Source) thin -> Target,
) -> RaisingCallable[Arguments, Target, ErrorType]:
    comptime Adapter = _RaisingCallableResult[
        Arguments, Source, Target, ErrorType
    ]
    var environment = allocate_callable_environment(
        Adapter(value, convert), destroy_callable_environment[Adapter]
    )
    return RaisingCallable[Arguments, Target, ErrorType](
        environment, Adapter.invoke, value.identity()
    )

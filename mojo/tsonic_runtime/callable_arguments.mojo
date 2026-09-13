from .callable import (
    Callable,
    RaisingCallable,
    ErasedCallableContext,
    allocate_callable_environment,
    destroy_callable_environment,
)


@fieldwise_init
struct _CallableArguments[
    SourceArguments: Movable & Deinitable,
    TargetArguments: Movable & Deinitable,
    Result: Movable,
]:
    var callable: Callable[Self.SourceArguments, Self.Result]
    var project: def(var Self.TargetArguments) thin -> Self.SourceArguments

    @staticmethod
    def invoke(
        context: ErasedCallableContext, var arguments: Self.TargetArguments
    ) -> Self.Result:
        var adapter = context.unsafe_bitcast[Self]()
        return adapter[].callable.call(adapter[].project(arguments^))


def adapt_callable_arguments[
    SourceArguments: Movable & Deinitable,
    TargetArguments: Movable & Deinitable,
    Result: Movable,
](
    value: Callable[SourceArguments, Result],
    project: def(var TargetArguments) thin -> SourceArguments,
) -> Callable[TargetArguments, Result]:
    comptime Adapter = _CallableArguments[
        SourceArguments, TargetArguments, Result
    ]
    var environment = allocate_callable_environment(
        Adapter(value, project), destroy_callable_environment[Adapter]
    )
    return Callable[TargetArguments, Result](
        environment, Adapter.invoke, value.identity()
    )


@fieldwise_init
struct _RaisingCallableArguments[
    SourceArguments: Movable & Deinitable,
    TargetArguments: Movable & Deinitable,
    Result: Movable,
    ErrorType: AnyType,
]:
    var callable: RaisingCallable[
        Self.SourceArguments, Self.Result, Self.ErrorType
    ]
    var project: def(var Self.TargetArguments) thin -> Self.SourceArguments

    @staticmethod
    def invoke(
        context: ErasedCallableContext, var arguments: Self.TargetArguments
    ) raises (Self.ErrorType) -> Self.Result:
        var adapter = context.unsafe_bitcast[Self]()
        return adapter[].callable.call(adapter[].project(arguments^))


def adapt_raising_callable_arguments[
    SourceArguments: Movable & Deinitable,
    TargetArguments: Movable & Deinitable,
    Result: Movable,
    ErrorType: AnyType,
](
    value: RaisingCallable[SourceArguments, Result, ErrorType],
    project: def(var TargetArguments) thin -> SourceArguments,
) -> RaisingCallable[TargetArguments, Result, ErrorType]:
    comptime Adapter = _RaisingCallableArguments[
        SourceArguments, TargetArguments, Result, ErrorType
    ]
    var environment = allocate_callable_environment(
        Adapter(value, project), destroy_callable_environment[Adapter]
    )
    return RaisingCallable[TargetArguments, Result, ErrorType](
        environment, Adapter.invoke, value.identity()
    )

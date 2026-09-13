from .callable import (
    Callable,
    ErasedCallableContext,
    RaisingCallable,
    allocate_callable_environment,
    destroy_callable_environment,
)
from .project_object import ProjectObject


@fieldwise_init
struct ProjectCallableEnvironment[
    Arguments: Movable & Deinitable,
    Result: Movable,
]:
    var object: ProjectObject
    var invoke: def(ProjectObject, var Self.Arguments) thin -> Self.Result

    @staticmethod
    def call(
        context: ErasedCallableContext,
        var arguments: Self.Arguments,
    ) -> Self.Result:
        var pointer = context.unsafe_bitcast[
            ProjectCallableEnvironment[Self.Arguments, Self.Result]
        ]()
        return pointer[].invoke(pointer[].object, arguments^)

    @staticmethod
    def destroy(context: ErasedCallableContext):
        destroy_callable_environment[
            ProjectCallableEnvironment[Self.Arguments, Self.Result]
        ](context)


def bind_project_callable[
    Arguments: Movable & Deinitable,
    Result: Movable,
](
    object: ProjectObject,
    invoke: def(ProjectObject, var Arguments) thin -> Result,
) -> Callable[Arguments, Result]:
    comptime Environment = ProjectCallableEnvironment[Arguments, Result]
    var environment = allocate_callable_environment(
        Environment(object, invoke),
        Environment.destroy,
    )
    return Callable[Arguments, Result](environment, Environment.call)


@fieldwise_init
struct RaisingProjectCallableEnvironment[
    Arguments: Movable & Deinitable,
    Result: Movable,
    ErrorType: AnyType,
]:
    var object: ProjectObject
    var invoke: def(ProjectObject, var Self.Arguments) thin raises (
        Self.ErrorType
    ) -> Self.Result

    @staticmethod
    def call(
        context: ErasedCallableContext,
        var arguments: Self.Arguments,
    ) raises (Self.ErrorType) -> Self.Result:
        var pointer = context.unsafe_bitcast[
            RaisingProjectCallableEnvironment[
                Self.Arguments, Self.Result, Self.ErrorType
            ]
        ]()
        return pointer[].invoke(pointer[].object, arguments^)

    @staticmethod
    def destroy(context: ErasedCallableContext):
        destroy_callable_environment[
            RaisingProjectCallableEnvironment[
                Self.Arguments, Self.Result, Self.ErrorType
            ]
        ](context)


def bind_raising_project_callable[
    Arguments: Movable & Deinitable,
    Result: Movable,
    ErrorType: AnyType,
](
    object: ProjectObject,
    invoke: def(ProjectObject, var Arguments) thin raises ErrorType -> Result,
) -> RaisingCallable[Arguments, Result, ErrorType]:
    comptime Environment = RaisingProjectCallableEnvironment[
        Arguments, Result, ErrorType
    ]
    var environment = allocate_callable_environment(
        Environment(object, invoke),
        Environment.destroy,
    )
    return RaisingCallable[Arguments, Result, ErrorType](
        environment, Environment.call
    )

from std.memory import ArcPointer
from std.memory.alloc import unsafe_alloc

from .callable import (
    Callable,
    ErasedCallableContext,
    ErasedCallableEnvironment,
    allocate_callable_environment,
    destroy_callable_environment,
)
from .closed_coroutine import ClosedRaisingCoroutine


def take_async_invocation[
    Arguments: Movable & Deinitable
](context: ErasedCallableContext) -> Tuple[
    ArcPointer[ErasedCallableEnvironment], Arguments
]:
    comptime Invocation = Tuple[
        ArcPointer[ErasedCallableEnvironment], Arguments
    ]
    var pointer = context.unsafe_bitcast[Invocation]()
    var invocation = pointer.unsafe_take_pointee()
    pointer.unsafe_free()
    return invocation^


@fieldwise_init
struct _AsyncCallableEnvironment[
    Arguments: Movable & Deinitable,
    Result: Movable,
]:
    var environment: ArcPointer[ErasedCallableEnvironment]
    var start: def(ErasedCallableContext) thin -> ClosedRaisingCoroutine[
        Self.Result
    ]

    @staticmethod
    def invoke(
        context: ErasedCallableContext, var arguments: Self.Arguments
    ) -> ClosedRaisingCoroutine[Self.Result]:
        comptime Invocation = Tuple[
            ArcPointer[ErasedCallableEnvironment], Self.Arguments
        ]
        var environment = context.unsafe_bitcast[Self]()
        var invocation = unsafe_alloc[Invocation](1)
        invocation.unsafe_write((environment[].environment, arguments^))
        return environment[].start(invocation.unsafe_bitcast[NoneType]())


def make_async_callable[
    Arguments: Movable & Deinitable,
    Result: Movable,
](
    environment: ArcPointer[ErasedCallableEnvironment],
    start: def(ErasedCallableContext) thin -> ClosedRaisingCoroutine[Result],
) -> Callable[Arguments, ClosedRaisingCoroutine[Result]]:
    comptime Adapter = _AsyncCallableEnvironment[Arguments, Result]
    var adapter = allocate_callable_environment(
        Adapter(environment, start), destroy_callable_environment[Adapter]
    )
    return Callable[Arguments, ClosedRaisingCoroutine[Result]](
        adapter, Adapter.invoke, environment
    )

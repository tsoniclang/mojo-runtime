from std.testing import assert_equal, assert_true
from std.utils import Variant
from tsonic_runtime import (
    Callable,
    RaisingCallable,
    ErasedCallableContext,
    allocate_callable_environment,
    destroy_callable_environment,
    create_raising_task,
    widen_callable,
    ClosedRaisingCoroutine,
)
from tsonic_runtime import adapt_callable_result, adapt_raising_callable_result

comptime Future = ClosedRaisingCoroutine[Int]
comptime Result = Variant[Bool, Future]


def selected_result(var value: Future) -> Result:
    return Result(value^)


@fieldwise_init
struct Environment:
    @staticmethod
    async def result() raises -> Int:
        return 42

    @staticmethod
    def invoke(
        context: ErasedCallableContext, var arguments: Tuple[]
    ) -> Future:
        _ = context
        _ = arguments
        return Environment.result()


def main() raises:
    var environment = allocate_callable_environment(
        Environment(), destroy_callable_environment[Environment]
    )
    var callback = Callable[Tuple[], Future](environment, Environment.invoke)
    var widened = widen_callable(callback)
    assert_equal(create_raising_task(callback.call(())).wait(), 42)
    assert_equal(create_raising_task(widened.call(())).wait(), 42)
    var converted = adapt_callable_result(callback, selected_result)
    var raising_converted = adapt_raising_callable_result(
        widened, selected_result
    )
    assert_true(callback.identity() is converted.identity())
    assert_true(widened.identity() is raising_converted.identity())
    var first = converted.call(())
    assert_equal(create_raising_task(first^.unsafe_unwrap[Future]()).wait(), 42)
    var second = raising_converted.call(())
    assert_equal(
        create_raising_task(second^.unsafe_unwrap[Future]()).wait(), 42
    )

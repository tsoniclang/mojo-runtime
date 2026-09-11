from std.testing import assert_equal
from tsonic_runtime import Callable, RaisingCallable, ErasedCallableContext, allocate_callable_environment, destroy_callable_environment, create_raising_task, widen_callable


@fieldwise_init
struct Environment:
    @staticmethod
    async def result() raises -> Int:
        return 42

    @staticmethod
    def invoke(context: ErasedCallableContext, var arguments: Tuple[]) -> RaisingCoroutine[Int, ...]:
        _ = context
        _ = arguments
        return Environment.result()


def main() raises:
    var environment = allocate_callable_environment(Environment(), destroy_callable_environment[Environment])
    var callback = Callable[Tuple[], RaisingCoroutine[Int, ...]](environment, Environment.invoke)
    var widened = widen_callable(callback)
    assert_equal(create_raising_task(callback.call(())).get(), 42)
    assert_equal(create_raising_task(widened.call(())).get(), 42)

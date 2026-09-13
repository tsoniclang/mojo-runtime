from std.testing import assert_equal, assert_true
from tsonic_runtime import (
    Callable,
    RaisingCallable,
    Location,
    TsError,
    ErasedCallableContext,
    adapt_callable_arguments,
    adapt_raising_callable_arguments,
    allocate_callable_environment,
    destroy_callable_environment,
)


@fieldwise_init
struct Action:
    var calls: Location[Int]

    @staticmethod
    def empty(context: ErasedCallableContext, var _arguments: Tuple[]) -> Int:
        var action = context.unsafe_bitcast[Self]()
        action[].calls.write(action[].calls.read() + 1)
        return 3

    @staticmethod
    def first(
        context: ErasedCallableContext, var arguments: Tuple[String]
    ) -> String:
        var action = context.unsafe_bitcast[Self]()
        action[].calls.write(action[].calls.read() + 1)
        return arguments[0] + "!"

    @staticmethod
    def failure(
        context: ErasedCallableContext, var _arguments: Tuple[]
    ) raises TsError -> Int:
        var action = context.unsafe_bitcast[Self]()
        action[].calls.write(action[].calls.read() + 1)
        raise TsError("SelectedError", "exact-message", String("exact-stack"))


def no_arguments(var _arguments: Tuple[Int, String]) -> Tuple[]:
    return ()


def first_argument(var arguments: Tuple[String, Int]) -> Tuple[String]:
    return (arguments[0].copy(),)


def main() raises:
    var calls = Location(0)
    var environment = allocate_callable_environment(
        Action(calls), destroy_callable_environment[Action]
    )
    var source = Callable[Tuple[], Int](environment, Action.empty)
    var adapted = adapt_callable_arguments[Tuple[], Tuple[Int, String], Int](
        source, no_arguments
    )
    var again = adapt_callable_arguments[Tuple[], Tuple[Int, String], Int](
        source, no_arguments
    )
    assert_true(adapted.same(again))
    assert_true(adapted.identity().ptr() == source.identity().ptr())
    assert_equal(adapted.call((17, "unused")), 3)
    assert_equal(calls.read(), 1)
    var first = Callable[Tuple[String], String](environment, Action.first)
    var prefix = adapt_callable_arguments[
        Tuple[String], Tuple[String, Int], String
    ](first, first_argument)
    assert_equal(prefix.call(("kept", 99)), "kept!")
    assert_equal(calls.read(), 2)
    var raising = RaisingCallable[Tuple[], Int, TsError](
        environment, Action.failure
    )
    var failure = adapt_raising_callable_arguments[
        Tuple[], Tuple[Int, String], Int, TsError
    ](raising, no_arguments)
    assert_true(failure.identity().ptr() == raising.identity().ptr())
    var rejected = False
    try:
        _ = failure.call((1, "unused"))
    except error:
        assert_equal(error.name, "SelectedError")
        assert_equal(error.message, "exact-message")
        assert_equal(error.stack.value(), "exact-stack")
        rejected = True
    assert_true(rejected)
    assert_equal(calls.read(), 3)

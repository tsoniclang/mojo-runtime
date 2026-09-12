from std.memory import ArcPointer
from std.testing import assert_equal, assert_true
from tsonic_runtime import (
    ClosedRaisingCoroutine,
    ErasedCallableContext,
    allocate_callable_environment,
    create_raising_task,
    destroy_callable_environment,
    make_async_callable,
    take_async_invocation,
)


@fieldwise_init
struct State:
    var value: Int
    var argument_bytes: Int
    var destroyed: Int
    var arguments_destroyed: Int


@fieldwise_init
struct Argument:
    var state: ArcPointer[State]
    var value: String

    def __deinit__(deinit self):
        self.state[].arguments_destroyed += 1


@fieldwise_init
struct Environment:
    var state: ArcPointer[State]

    def __deinit__(deinit self):
        self.state[].destroyed += 1

    @staticmethod
    def start(context: ErasedCallableContext) -> ClosedRaisingCoroutine[Int]:
        return Environment.execute(context)

    @staticmethod
    async def execute(context: ErasedCallableContext) raises -> Int:
        var invocation = take_async_invocation[Tuple[Int, Argument]](context)
        ref arguments = invocation[1]
        try:
            var environment = invocation[0][].context.unsafe_bitcast[
                Environment
            ]()
            if arguments[0] < 0:
                raise Error("negative step")
            environment[].state[].value += arguments[0]
            environment[].state[].argument_bytes += arguments[
                1
            ].value.byte_length()
            return environment[].state[].value
        finally:
            _ = invocation


def check_pending_pair(state: ArcPointer[State]) raises:
    var environment = allocate_callable_environment(
        Environment(state), destroy_callable_environment[Environment]
    )
    var callback = make_async_callable[Tuple[Int, Argument], Int](
        environment, Environment.start
    )
    var same_callback = callback
    assert_true(callback.same(same_callback))
    var first = callback.call(
        (
            2,
            Argument(
                state, String("long first argument retained beyond the factory")
            ),
        )
    )
    var second = same_callback.call(
        (
            3,
            Argument(
                state,
                String("long second argument retained beyond the factory"),
            ),
        )
    )
    _ = environment
    _ = callback
    _ = same_callback
    var initial_value = state[].value
    var initial_destroyed = state[].destroyed
    var first_value: Int
    var first_destroyed: Int
    var first_argument_destroyed: Int
    var second_value: Int
    try:
        first_value = create_raising_task(first^).wait()
        first_destroyed = state[].destroyed
        first_argument_destroyed = state[].arguments_destroyed
    finally:
        second_value = create_raising_task(second^).wait()
    assert_equal(initial_value, 10)
    assert_equal(initial_destroyed, 0)
    assert_equal(first_value, 12)
    assert_equal(first_destroyed, 0)
    assert_equal(first_argument_destroyed, 1)
    assert_equal(second_value, 15)


def escaped_failure(state: ArcPointer[State]) -> ClosedRaisingCoroutine[Int]:
    var environment = allocate_callable_environment(
        Environment(state), destroy_callable_environment[Environment]
    )
    var callback = make_async_callable[Tuple[Int, Argument], Int](
        environment, Environment.start
    )
    return callback.call(
        (-1, Argument(state, String("owned argument on the failing path")))
    )


def main() raises:
    var state = ArcPointer(State(10, 0, 0, 0))
    check_pending_pair(state)
    assert_equal(state[].destroyed, 1)
    assert_equal(state[].arguments_destroyed, 2)
    assert_equal(
        state[].argument_bytes,
        String("long first argument retained beyond the factory").byte_length()
        + String(
            "long second argument retained beyond the factory"
        ).byte_length(),
    )
    var failure = escaped_failure(state)
    var rejected = False
    try:
        _ = create_raising_task(failure^).wait()
    except error:
        assert_equal(String(error), "negative step")
        rejected = True
    assert_true(rejected)
    assert_equal(state[].value, 15)
    assert_equal(state[].destroyed, 2)
    assert_equal(state[].arguments_destroyed, 3)

from std.testing import assert_equal, assert_false, assert_true
from tsonic_runtime import (
    Callable,
    ErasedCallableContext,
    RaisingCallable,
    allocate_callable_environment,
    destroy_callable_environment,
)


struct AddEnvironment:
    var offset: Int

    def __init__(out self, offset: Int):
        self.offset = offset

    @staticmethod
    def invoke(
        context: ErasedCallableContext,
        var arguments: Tuple[Int, Int],
    ) -> Int:
        var environment = context.unsafe_bitcast[AddEnvironment]()
        return environment[].offset + arguments[0] + arguments[1]

    @staticmethod
    def raising_invoke(
        context: ErasedCallableContext,
        var arguments: Tuple[Int],
    ) raises -> None:
        var environment = context.unsafe_bitcast[AddEnvironment]()
        if arguments[0] < 0:
            raise Error("negative callback argument")
        print(environment[].offset + arguments[0])

    @staticmethod
    def destroy(context: ErasedCallableContext):
        destroy_callable_environment[AddEnvironment](context)


def main() raises:
    var first = allocate_callable_environment(
        AddEnvironment(40), AddEnvironment.destroy
    )
    var callback = Callable[Tuple[Int, Int], Int](first, AddEnvironment.invoke)
    assert_equal(callback.call((1, 1)), 42)
    var callback_copy = callback
    assert_true(callback.same(callback_copy))

    var second = allocate_callable_environment(
        AddEnvironment(40), AddEnvironment.destroy
    )
    var distinct = Callable[Tuple[Int, Int], Int](second, AddEnvironment.invoke)
    assert_false(callback.same(distinct))

    var raising_environment = allocate_callable_environment(
        AddEnvironment(40), AddEnvironment.destroy
    )
    var raising = RaisingCallable[Tuple[Int], NoneType](
        raising_environment, AddEnvironment.raising_invoke
    )
    raising.call((2,))
    try:
        raising.call((-1,))
        assert_true(False)
    except:
        pass

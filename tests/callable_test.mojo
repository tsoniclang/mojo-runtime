from std.collections import Optional
from std.testing import assert_equal, assert_false, assert_true
from tsonic_runtime import (
    Callable,
    ErasedCallableContext,
    RaisingCallable,
    adapt_raising_callable_never_result,
    allocate_callable_environment,
    destroy_callable_environment,
    erase_callable_error,
    widen_callable,
    Location,
)


@fieldwise_init
struct CallbackError(Copyable, Writable):
    var code: Int

    def write_to(self, mut writer: Some[Writer]):
        writer.write("callback error ", self.code)


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
    def typed_raising_invoke(
        context: ErasedCallableContext,
        var arguments: Tuple[Int],
    ) raises CallbackError -> Int:
        _ = context
        if arguments[0] < 0:
            raise CallbackError(42)
        return arguments[0]

    @staticmethod
    def typed_never_invoke(
        context: ErasedCallableContext,
        var arguments: Tuple[Int],
    ) raises CallbackError -> Never:
        _ = context
        raise CallbackError(arguments[0])

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

    var widened = widen_callable(callback)
    assert_equal(widened.call((1, 1)), 42)
    var typed_widened = widen_callable[Tuple[Int, Int], Int, CallbackError](
        callback
    )
    var typed_widened_result: Int
    try:
        typed_widened_result = typed_widened.call((1, 1))
    except:
        typed_widened_result = -1
    assert_equal(typed_widened_result, 42)

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

    var typed_environment = allocate_callable_environment(
        AddEnvironment(0), AddEnvironment.destroy
    )
    var typed_raising = RaisingCallable[Tuple[Int], Int, CallbackError](
        typed_environment, AddEnvironment.typed_raising_invoke
    )
    var typed_error_code = 0
    try:
        _ = typed_raising.call((-1,))
    except error:
        typed_error_code = error.code
    assert_equal(typed_error_code, 42)

    var never_environment = allocate_callable_environment(
        AddEnvironment(0), AddEnvironment.destroy
    )
    var never_raising = RaisingCallable[Tuple[Int], Never, CallbackError](
        never_environment, AddEnvironment.typed_never_invoke
    )
    var adapted_never = adapt_raising_callable_never_result[
        Tuple[Int], Int, CallbackError
    ](never_raising)
    var adapted_error_code = 0
    try:
        _ = adapted_never.call((17,))
    except error:
        adapted_error_code = error.code
    assert_equal(adapted_error_code, 17)

    var erased_raising = erase_callable_error(typed_raising)
    var erased_message = String()
    try:
        _ = erased_raising.call((-1,))
    except error:
        erased_message = String(error)
    assert_equal(erased_message, "callback error 42")

    var recursive_slot = Location(
        Optional[RaisingCallable[Tuple[Int], Int, CallbackError]]()
    )
    recursive_slot.write(Optional(typed_raising))
    var recursive_callable = recursive_slot.borrow().value()
    var recursive_result: Int
    try:
        recursive_result = recursive_callable.call((7,))
    except:
        recursive_result = -1
    assert_equal(recursive_result, 7)

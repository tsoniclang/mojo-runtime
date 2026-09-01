from std.memory import ArcPointer, unsafe_destroy_n
from std.memory.alloc import unsafe_alloc


comptime ErasedCallableContext = MutOpaquePointer[MutUntrackedOrigin]
comptime ErasedCallableDestroy = def(ErasedCallableContext) thin -> None


struct ErasedCallableEnvironment:
    var context: ErasedCallableContext
    var destroy_function: ErasedCallableDestroy

    def __init__(
        out self,
        context: ErasedCallableContext,
        destroy_function: ErasedCallableDestroy,
    ):
        self.context = context
        self.destroy_function = destroy_function

    def __deinit__(deinit self):
        self.destroy_function(self.context)


def allocate_callable_environment[
    T: Movable & Deinitable
](
    var value: T,
    destroy_function: ErasedCallableDestroy,
) -> ArcPointer[
    ErasedCallableEnvironment
]:
    var pointer = unsafe_alloc[T](1)
    pointer.unsafe_write(value^)
    var context = pointer.unsafe_bitcast[NoneType]()
    return ArcPointer(ErasedCallableEnvironment(context, destroy_function))


def destroy_callable_environment[
    T: Movable & Deinitable
](context: ErasedCallableContext,):
    var pointer = context.unsafe_bitcast[T]()
    unsafe_destroy_n(pointer, count=1)
    pointer.unsafe_free()


struct Callable[
    Arguments: Movable & Deinitable,
    Result: Movable & Deinitable,
](ImplicitlyCopyable):
    var _environment: ArcPointer[ErasedCallableEnvironment]
    var _invoke: def(
        ErasedCallableContext, var Self.Arguments
    ) thin -> Self.Result

    def __init__(
        out self,
        environment: ArcPointer[ErasedCallableEnvironment],
        invoke: def(
            ErasedCallableContext, var Self.Arguments
        ) thin -> Self.Result,
    ):
        self._environment = environment
        self._invoke = invoke

    def call(self, var arguments: Self.Arguments) -> Self.Result:
        return self._invoke(self._environment[].context, arguments^)

    def same(self, other: Self) -> Bool:
        return self._environment is other._environment


struct RaisingCallable[
    Arguments: Movable & Deinitable,
    Result: Movable & Deinitable,
](ImplicitlyCopyable):
    var _environment: ArcPointer[ErasedCallableEnvironment]
    var _invoke: def(
        ErasedCallableContext, var Self.Arguments
    ) thin raises -> Self.Result

    def __init__(
        out self,
        environment: ArcPointer[ErasedCallableEnvironment],
        invoke: def(
            ErasedCallableContext, var Self.Arguments
        ) thin raises -> Self.Result,
    ):
        self._environment = environment
        self._invoke = invoke

    def call(self, var arguments: Self.Arguments) raises -> Self.Result:
        return self._invoke(self._environment[].context, arguments^)

    def same(self, other: Self) -> Bool:
        return self._environment is other._environment


@fieldwise_init
struct CallableRaiseAdapter[
    Arguments: Movable & Deinitable,
    Result: Movable & Deinitable,
]:
    var callable: Callable[Self.Arguments, Self.Result]

    @staticmethod
    def invoke(
        context: ErasedCallableContext,
        var arguments: Self.Arguments,
    ) raises -> Self.Result:
        var pointer = context.unsafe_bitcast[
            CallableRaiseAdapter[Self.Arguments, Self.Result]
        ]()
        return pointer[].callable.call(arguments^)

    @staticmethod
    def destroy(context: ErasedCallableContext):
        destroy_callable_environment[
            CallableRaiseAdapter[Self.Arguments, Self.Result]
        ](context)


def widen_callable[
    Arguments: Movable & Deinitable,
    Result: Movable & Deinitable,
](value: Callable[Arguments, Result]) -> RaisingCallable[Arguments, Result]:
    comptime Adapter = CallableRaiseAdapter[Arguments, Result]
    var environment = allocate_callable_environment(
        Adapter(value),
        Adapter.destroy,
    )
    return RaisingCallable[Arguments, Result](environment, Adapter.invoke)

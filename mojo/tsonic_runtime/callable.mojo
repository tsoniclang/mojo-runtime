from std.memory import ArcPointer, unsafe_destroy_n
from std.memory.alloc import unsafe_alloc


comptime ErasedCallableContext = MutOpaquePointer[MutUntrackedOrigin]
comptime ErasedCallableDestroy = def(ErasedCallableContext) thin -> None


def discard_callable_result[T: Movable & Deinitable](var _value: T):
    pass


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
    Result: Movable,
](Equatable, ImplicitlyCopyable):
    var _environment: ArcPointer[ErasedCallableEnvironment]
    var _identity: ArcPointer[ErasedCallableEnvironment]
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
        self._identity = environment
        self._invoke = invoke

    def __init__(
        out self,
        environment: ArcPointer[ErasedCallableEnvironment],
        invoke: def(
            ErasedCallableContext, var Self.Arguments
        ) thin -> Self.Result,
        identity: ArcPointer[ErasedCallableEnvironment],
    ):
        self._environment = environment
        self._identity = identity
        self._invoke = invoke

    def call(self, var arguments: Self.Arguments) -> Self.Result:
        return self._invoke(self._environment[].context, arguments^)

    def same(self, other: Self) -> Bool:
        return self._identity is other._identity

    def __eq__(self, other: Self) -> Bool:
        return self.same(other)

    def __ne__(self, other: Self) -> Bool:
        return not self.same(other)

    def identity(self) -> ArcPointer[ErasedCallableEnvironment]:
        return self._identity


struct RaisingCallable[
    Arguments: Movable & Deinitable,
    Result: Movable,
    ErrorType: AnyType = Error,
](Equatable, ImplicitlyCopyable):
    var _environment: ArcPointer[ErasedCallableEnvironment]
    var _identity: ArcPointer[ErasedCallableEnvironment]
    var _invoke: def(ErasedCallableContext, var Self.Arguments) thin raises (
        Self.ErrorType
    ) -> Self.Result

    def __init__(
        out self,
        environment: ArcPointer[ErasedCallableEnvironment],
        invoke: def(ErasedCallableContext, var Self.Arguments) thin raises (
            Self.ErrorType
        ) -> Self.Result,
    ):
        self._environment = environment
        self._identity = environment
        self._invoke = invoke

    def __init__(
        out self,
        environment: ArcPointer[ErasedCallableEnvironment],
        invoke: def(ErasedCallableContext, var Self.Arguments) thin raises (
            Self.ErrorType
        ) -> Self.Result,
        identity: ArcPointer[ErasedCallableEnvironment],
    ):
        self._environment = environment
        self._identity = identity
        self._invoke = invoke

    def call(
        self, var arguments: Self.Arguments
    ) raises (Self.ErrorType) -> Self.Result:
        return self._invoke(self._environment[].context, arguments^)

    def same(self, other: Self) -> Bool:
        return self._identity is other._identity

    def __eq__(self, other: Self) -> Bool:
        return self.same(other)

    def __ne__(self, other: Self) -> Bool:
        return not self.same(other)

    def identity(self) -> ArcPointer[ErasedCallableEnvironment]:
        return self._identity


@fieldwise_init
struct CallableRaiseAdapter[
    Arguments: Movable & Deinitable,
    Result: Movable,
    ErrorType: AnyType,
]:
    var callable: Callable[Self.Arguments, Self.Result]

    @staticmethod
    def invoke(
        context: ErasedCallableContext,
        var arguments: Self.Arguments,
    ) raises (Self.ErrorType) -> Self.Result:
        var pointer = context.unsafe_bitcast[
            CallableRaiseAdapter[Self.Arguments, Self.Result, Self.ErrorType]
        ]()
        return pointer[].callable.call(arguments^)

    @staticmethod
    def destroy(context: ErasedCallableContext):
        destroy_callable_environment[
            CallableRaiseAdapter[Self.Arguments, Self.Result, Self.ErrorType]
        ](context)


def widen_callable[
    Arguments: Movable & Deinitable,
    Result: Movable,
    ErrorType: AnyType = Error,
](value: Callable[Arguments, Result]) -> RaisingCallable[
    Arguments, Result, ErrorType
]:
    comptime Adapter = CallableRaiseAdapter[Arguments, Result, ErrorType]
    var environment = allocate_callable_environment(
        Adapter(value),
        Adapter.destroy,
    )
    return RaisingCallable[Arguments, Result, ErrorType](
        environment, Adapter.invoke, value.identity()
    )


@fieldwise_init
struct CallableNeverResultAdapter[
    Arguments: Movable & Deinitable,
    Result: Movable,
]:
    var callable: Callable[Self.Arguments, Never]

    @staticmethod
    def invoke(
        context: ErasedCallableContext,
        var arguments: Self.Arguments,
    ) -> Self.Result:
        var pointer = context.unsafe_bitcast[
            CallableNeverResultAdapter[Self.Arguments, Self.Result]
        ]()
        pointer[].callable.call(arguments^)

    @staticmethod
    def destroy(context: ErasedCallableContext):
        destroy_callable_environment[
            CallableNeverResultAdapter[Self.Arguments, Self.Result]
        ](context)


def adapt_callable_never_result[
    Arguments: Movable & Deinitable,
    Result: Movable,
](value: Callable[Arguments, Never]) -> Callable[Arguments, Result]:
    comptime Adapter = CallableNeverResultAdapter[Arguments, Result]
    var environment = allocate_callable_environment(
        Adapter(value), Adapter.destroy
    )
    return Callable[Arguments, Result](
        environment, Adapter.invoke, value.identity()
    )


@fieldwise_init
struct RaisingCallableNeverResultAdapter[
    Arguments: Movable & Deinitable,
    Result: Movable,
    ErrorType: AnyType,
]:
    var callable: RaisingCallable[Self.Arguments, Never, Self.ErrorType]

    @staticmethod
    def invoke(
        context: ErasedCallableContext,
        var arguments: Self.Arguments,
    ) raises (Self.ErrorType) -> Self.Result:
        var pointer = context.unsafe_bitcast[
            RaisingCallableNeverResultAdapter[
                Self.Arguments, Self.Result, Self.ErrorType
            ]
        ]()
        pointer[].callable.call(arguments^)

    @staticmethod
    def destroy(context: ErasedCallableContext):
        destroy_callable_environment[
            RaisingCallableNeverResultAdapter[
                Self.Arguments, Self.Result, Self.ErrorType
            ]
        ](context)


def adapt_raising_callable_never_result[
    Arguments: Movable & Deinitable,
    Result: Movable,
    ErrorType: AnyType,
](value: RaisingCallable[Arguments, Never, ErrorType]) -> RaisingCallable[
    Arguments, Result, ErrorType
]:
    comptime Adapter = RaisingCallableNeverResultAdapter[
        Arguments, Result, ErrorType
    ]
    var environment = allocate_callable_environment(
        Adapter(value), Adapter.destroy
    )
    return RaisingCallable[Arguments, Result, ErrorType](
        environment, Adapter.invoke, value.identity()
    )


@fieldwise_init
struct CallableErrorAdapter[
    Arguments: Movable & Deinitable,
    Result: Movable,
    ErrorType: Writable & Deinitable,
]:
    var callable: RaisingCallable[Self.Arguments, Self.Result, Self.ErrorType]

    @staticmethod
    def invoke(
        context: ErasedCallableContext,
        var arguments: Self.Arguments,
    ) raises -> Self.Result:
        var pointer = context.unsafe_bitcast[
            CallableErrorAdapter[Self.Arguments, Self.Result, Self.ErrorType]
        ]()
        try:
            return pointer[].callable.call(arguments^)
        except error:
            raise Error(String(error))

    @staticmethod
    def destroy(context: ErasedCallableContext):
        destroy_callable_environment[
            CallableErrorAdapter[Self.Arguments, Self.Result, Self.ErrorType]
        ](context)


def erase_callable_error[
    Arguments: Movable & Deinitable,
    Result: Movable,
    ErrorType: Writable & Deinitable,
](value: RaisingCallable[Arguments, Result, ErrorType]) -> RaisingCallable[
    Arguments, Result
]:
    comptime Adapter = CallableErrorAdapter[Arguments, Result, ErrorType]
    var environment = allocate_callable_environment(
        Adapter(value),
        Adapter.destroy,
    )
    return RaisingCallable[Arguments, Result](
        environment, Adapter.invoke, value.identity()
    )

from std.memory import ArcPointer
from std.memory.arc_pointer import WeakPointer
from .callable import Callable, ErasedCallableContext, allocate_callable_environment, destroy_callable_environment


@fieldwise_init
struct _ReferenceLiveness[Value: Movable & Deinitable]:
    var owner: WeakPointer[Self.Value]

    @staticmethod
    def alive(context: ErasedCallableContext, var _arguments: Tuple[]) -> Bool:
        return context.unsafe_bitcast[Self]()[].owner.strong_count() != 0


struct WeakReferenceIdentity(ImplicitlyCopyable):
    var address: UInt
    var _alive: Callable[Tuple[], Bool]

    def __init__[Value: Movable & Deinitable](out self, owner: ArcPointer[Value]):
        self.address = UInt(Int(owner.ptr()))
        var environment = allocate_callable_environment(
            _ReferenceLiveness[Value](WeakPointer[Value](downgrade=owner)),
            destroy_callable_environment[_ReferenceLiveness[Value]],
        )
        self._alive = Callable[Tuple[], Bool](environment, _ReferenceLiveness[Value].alive)

    def is_alive(self) -> Bool:
        return self._alive.call(())

    def same(self, other: Self) -> Bool:
        return self.address == other.address and self.is_alive() and other.is_alive()

from std.memory import ArcPointer
from .reference_identity import WeakReferenceIdentity


struct StructuralObject[Storage: Movable & Deinitable](ImplicitlyCopyable):
    var _state: ArcPointer[Self.Storage]

    def __init__(out self, var storage: Self.Storage):
        self._state = ArcPointer(storage^)

    def weak_identity(self) -> WeakReferenceIdentity:
        return WeakReferenceIdentity(self._state)

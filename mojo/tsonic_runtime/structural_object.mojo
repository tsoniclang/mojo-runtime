from std.memory import ArcPointer


struct StructuralObject[Storage: Movable & Deinitable](ImplicitlyCopyable):
    var _state: ArcPointer[Self.Storage]

    def __init__(out self, var storage: Self.Storage):
        self._state = ArcPointer(storage^)

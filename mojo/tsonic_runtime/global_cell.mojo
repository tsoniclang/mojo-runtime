from std.ffi import _Global


struct GlobalCell[
    T: Movable,
    //,
    name: StaticString,
    init_fn: def() thin -> T,
](Defaultable):
    def __init__(out self):
        pass

    @staticmethod
    def get() raises -> _Global[Self.name, Self.init_fn].ResultType:
        return _Global[Self.name, Self.init_fn].get_or_create_ptr()

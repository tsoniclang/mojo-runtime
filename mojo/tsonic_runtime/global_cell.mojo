from std.ffi import _Global
from std.os import abort


struct GlobalCell[
    T: Movable,
    //,
    name: StaticString,
    init_fn: def() thin -> T,
](Defaultable):
    def __init__(out self):
        pass

    @staticmethod
    def get() -> _Global[Self.name, Self.init_fn].ResultType:
        try:
            return _Global[Self.name, Self.init_fn].get_or_create_ptr()
        except error:
            abort(String(error))

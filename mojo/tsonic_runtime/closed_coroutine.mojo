from std.builtin._coroutine import Coroutine, RaisingCoroutine


async def _closed_capture_origin():
    pass


comptime ClosedCoroutine[T: Movable & Deinitable] = Coroutine[
    T, type_of(_closed_capture_origin()).origins
]
comptime ClosedRaisingCoroutine[T: Movable] = RaisingCoroutine[
    T, type_of(_closed_capture_origin()).origins
]

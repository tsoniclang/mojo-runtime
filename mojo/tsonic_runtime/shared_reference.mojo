from std.memory import ArcPointer, unsafe_destroy_n
from std.memory.alloc import unsafe_alloc


comptime ErasedSharedReferenceContext = MutOpaquePointer[MutUntrackedOrigin]
comptime ErasedSharedReferenceDestroy = def(
    ErasedSharedReferenceContext
) thin -> None


struct ErasedSharedReferenceStorage:
    var context: ErasedSharedReferenceContext
    var destroy_function: ErasedSharedReferenceDestroy

    def __init__(
        out self,
        context: ErasedSharedReferenceContext,
        destroy_function: ErasedSharedReferenceDestroy,
    ):
        self.context = context
        self.destroy_function = destroy_function

    def __deinit__(deinit self):
        self.destroy_function(self.context)


def _destroy_shared_reference[
    T: Movable & Deinitable
](context: ErasedSharedReferenceContext,):
    var pointer = context.unsafe_bitcast[T]()
    unsafe_destroy_n(pointer, count=1)
    pointer.unsafe_free()


struct SharedReference[T: AnyType](ImplicitlyCopyable):
    var _storage: ArcPointer[ErasedSharedReferenceStorage]

    def __init__[
        _T: Movable & Deinitable
    ](out self: SharedReference[_T], var value: _T,):
        var pointer = unsafe_alloc[_T](1)
        pointer.unsafe_write(value^)
        var context = pointer.unsafe_bitcast[NoneType]()
        self._storage = ArcPointer(
            ErasedSharedReferenceStorage(context, _destroy_shared_reference[_T])
        )

    def __getitem__[
        origin: Origin
    ](ref[origin] self,) -> ref[origin.unsafe_mut_cast[True]()] Self.T:
        return (
            self._storage[]
            .context.unsafe_bitcast[Self.T]()
            .unsafe_origin_cast[origin.unsafe_mut_cast[True]()]()[]
        )

    def __is__(self, other: Self) -> Bool:
        return self._storage is other._storage

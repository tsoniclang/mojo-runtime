from std.collections import Optional
from std.memory import ArcPointer, unsafe_destroy_n
from std.memory.alloc import unsafe_alloc
from .reference_identity import WeakReferenceIdentity


comptime ProjectObjectContext = MutOpaquePointer[MutUntrackedOrigin]
comptime ProjectObjectDestroy = def(ProjectObjectContext) thin -> None


struct ProjectObjectStorage:
    var context: ProjectObjectContext
    var destroy: ProjectObjectDestroy

    def __init__(
        out self,
        context: ProjectObjectContext,
        destroy: ProjectObjectDestroy,
    ):
        self.context = context
        self.destroy = destroy

    def __deinit__(deinit self):
        self.destroy(self.context)


def _destroy_project_object[
    T: Movable & Deinitable
](context: ProjectObjectContext):
    var pointer = context.unsafe_bitcast[T]()
    unsafe_destroy_n(pointer, count=1)
    pointer.unsafe_free()


struct ProjectObject(ImplicitlyCopyable):
    var _storage: ArcPointer[ProjectObjectStorage]

    def __init__[T: Movable & Deinitable](out self, var value: T):
        var pointer = unsafe_alloc[T](1)
        pointer.unsafe_write(value^)
        self._storage = ArcPointer(
            ProjectObjectStorage(
                pointer.unsafe_bitcast[NoneType](),
                _destroy_project_object[T],
            )
        )

    def state[
        T: AnyType,
        origin: Origin,
    ](ref[origin] self) -> ref[origin.unsafe_mut_cast[True]()] T:
        return (
            self._storage[]
            .context.unsafe_bitcast[T]()
            .unsafe_origin_cast[origin.unsafe_mut_cast[True]()]()[]
        )

    def same(self, other: Self) -> Bool:
        return self._storage is other._storage

    def identity_address(self) -> UInt:
        return UInt(Int(self._storage.unsafe_ptr()))

    def weak_identity(self) -> WeakReferenceIdentity:
        return WeakReferenceIdentity(self._storage)


def erase_project_view[T: Movable & Deinitable](var value: T) -> ProjectObject:
    return ProjectObject(value^)


def restore_project_view[
    T: ImplicitlyCopyable & Deinitable
](value: Optional[ProjectObject]) -> Optional[T]:
    if not value:
        return None
    return Optional[T](value.value().state[T]())

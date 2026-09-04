from std.memory import ArcPointer


struct Location[T: Movable & Deinitable](ImplicitlyCopyable):
    var _storage: ArcPointer[Self.T]

    def __init__(out self, var value: Self.T):
        self._storage = ArcPointer(value^)

    def read(self) -> Self.T where conforms_to(Self.T, Copyable):
        return self._storage[].copy()

    def borrow[
        origin: Origin
    ](ref[origin] self,) -> ref[ImmOrigin(origin)] Self.T:
        return self._storage.ptr().unsafe_origin_cast[ImmOrigin(origin)]()[]

    def borrow_mut[
        origin: Origin
    ](ref[origin] self,) -> ref[origin.unsafe_mut_cast[True]()] Self.T:
        return self._storage.ptr().unsafe_origin_cast[
            origin.unsafe_mut_cast[True]()
        ]()[]

    def write(mut self, var value: Self.T):
        self._storage[] = value^

    def same_storage(self, other: Self) -> Bool:
        return self._storage is other._storage


def equal_location[
    T: Movable & Deinitable
](left: Optional[Location[T]], right: Optional[Location[T]]) -> Bool:
    if left:
        return right and left.value().same_storage(right.value())
    return not right

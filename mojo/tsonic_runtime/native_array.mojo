from std.memory import ArcPointer
from std.sys import size_of
from .raw_pointer import RawPointer
from .native_location import NativeLocation
from .typed_location import TypedLocation


struct NativeArray[T: Movable & Deinitable](ImplicitlyCopyable):
    var _elements: ArcPointer[List[Self.T]]

    def __init__(out self, var elements: List[Self.T]):
        self._elements = ArcPointer(elements^)

    def _check_index(self, index: Int) raises:
        if index < 0 or index >= len(self._elements[]):
            raise Error("Native array location index is outside its allocation")

    def __getitem__(
        self, index: Int
    ) raises -> Self.T where conforms_to(Self.T, Copyable):
        self._check_index(index)
        return self._elements[][index].copy()

    def __setitem__(self, index: Int, var value: Self.T) raises:
        self._check_index(index)
        self._elements[][index] = value^

    def location(self, index: Int) raises -> TypedLocation[Self.T]:
        self._check_index(index)
        var start = UInt(Int(self._elements[].unsafe_ptr()))
        var element_size = UInt(size_of[Self.T]())
        if element_size == 0:
            raise Error(
                "A zero-sized element has no distinct physical native array"
                " address"
            )
        if UInt(len(self._elements[])) > UInt.MAX // element_size:
            raise Error("Native array allocation exceeds the address space")
        var raw = RawPointer.retained(
            self._elements, start, UInt(len(self._elements[])) * element_size
        )
        var address = start + UInt(index) * element_size
        return TypedLocation[Self.T](NativeLocation[Self.T](raw.at(address)))

from std.memory import ArcPointer

from .shared_reference import SharedReference


struct RawPointer(Copyable, Equatable):
    var _address: UInt

    def __init__(out self, address: UInt):
        self._address = address

    def __eq__(self, other: Self) -> Bool:
        return self._address == other._address


def raw_pointer_from_arc[
    T: Movable & Deinitable
](value: ArcPointer[T]) -> RawPointer:
    return RawPointer(UInt(Int(value.ptr())))


def raw_pointer_from_shared_reference(value: SharedReference) -> RawPointer:
    return RawPointer(value.identity_address())


def equal_raw_pointer(
    left: Optional[RawPointer], right: Optional[RawPointer]
) -> Bool:
    if left:
        return right and left.value() == right.value()
    return not right


def hash_raw_pointer(pointer: Optional[RawPointer]) -> Float64:
    if not pointer:
        return 0
    var value = pointer.value()._address
    value = value ^ (value >> 33)
    value = value * 0xFF51AFD7ED558CCD
    value = value ^ (value >> 33)
    return Float64(UInt32(value))

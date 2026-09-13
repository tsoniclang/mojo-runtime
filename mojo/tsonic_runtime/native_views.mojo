from .native_location import NativeLocation, require_native_layout
from .typed_location import TypedLocation
from .raw_pointer import RawPointer


def reinterpret_location[
    T: Movable & Deinitable,
    byte_size: Int,
    byte_alignment: Int,
    stride: Int,
    address_width: Int,
    little_endian: Bool,
](raw: Optional[RawPointer]) raises -> Optional[TypedLocation[T]]:
    require_native_layout[
        T, byte_size, byte_alignment, stride, address_width, little_endian
    ]()
    if not raw:
        return None
    var address = raw.value().copy()
    address.require_region(UInt(byte_size), UInt(byte_alignment))
    return TypedLocation[T](NativeLocation[T](address^))


def to_raw_location[
    T: Movable & Deinitable,
    byte_size: Int,
    byte_alignment: Int,
    stride: Int,
    address_width: Int,
    little_endian: Bool,
](pointer: Optional[TypedLocation[T]]) raises -> Optional[RawPointer]:
    require_native_layout[
        T, byte_size, byte_alignment, stride, address_width, little_endian
    ]()
    if not pointer:
        return None
    var result = pointer.value().to_raw()
    if result:
        result.value().require_region(UInt(byte_size), UInt(byte_alignment))
    return result^


def keep_alive[T: Movable & Deinitable](var _value: T):
    pass

from std.sys import size_of
from .raw_pointer import RawPointer


def raw_address[width: Int](pointer: Optional[RawPointer]) -> UInt64:
    comptime assert (
        width == 8 * size_of[UInt]()
    ), "Selected address ABI differs from the native target"
    return UInt64(pointer.value()._address) if pointer else 0


def raw_from_address[
    width: Int
](address: UInt64) raises -> Optional[RawPointer]:
    comptime assert (
        width == 8 * size_of[UInt]()
    ), "Selected address ABI differs from the native target"
    if UInt128(address) > UInt128(UInt.MAX):
        raise Error("Address integer exceeds the native address width")
    if address == 0:
        return None
    return RawPointer(UInt(address))


def offset_raw_unsigned[
    width: Int
](pointer: Optional[RawPointer], amount: UInt128) raises -> Optional[
    RawPointer
]:
    var current = UInt(raw_address[width](pointer))
    if amount > UInt128(UInt.MAX - current):
        raise Error("Raw byte offset exceeds the selected address width")
    var address = current + UInt(amount)
    if address == 0:
        return None
    return pointer.value().at(address) if pointer else RawPointer(address)


def offset_raw_signed[
    width: Int
](pointer: Optional[RawPointer], amount: Int128) raises -> Optional[RawPointer]:
    if amount >= 0:
        return offset_raw_unsigned[width](pointer, UInt128(amount))
    var current = UInt(raw_address[width](pointer))
    var magnitude = UInt128(-(amount + 1)) + 1
    if magnitude > UInt128(current):
        raise Error("Raw byte offset precedes the address space")
    var address = current - UInt(magnitude)
    if address == 0:
        return None
    return pointer.value().at(address) if pointer else RawPointer(address)

from .shared_reference import SharedReference


struct RawPointer(Copyable, Equatable):
    var _address: UInt
    var _owner: Optional[SharedReference]
    var _region_start: UInt
    var _region_size: UInt

    def __init__(out self, address: UInt):
        self._address = address
        self._owner = None
        self._region_start = 0
        self._region_size = 0

    @staticmethod
    def retained[
        Owner: Movable & Deinitable
    ](var owner: Owner, address: UInt, byte_size: UInt) raises -> Self:
        if address == 0 or byte_size > UInt.MAX - address:
            raise Error("Native allocation has invalid address bounds")
        var result = Self(address)
        result._owner = SharedReference(owner^)
        result._region_start = address
        result._region_size = byte_size
        return result^

    def require_region(self, byte_size: UInt, alignment: UInt) raises:
        if alignment == 0 or alignment & (alignment - 1) != 0:
            raise Error("Native view has invalid alignment")
        if self._address == 0 or self._address % alignment != 0:
            raise Error("Native view has an unaligned or null address")
        if byte_size > UInt.MAX - self._address:
            raise Error("Native view exceeds the address space")
        if self._owner:
            if self._address < self._region_start:
                raise Error("Native view precedes its retained allocation")
            var offset = self._address - self._region_start
            if (
                offset > self._region_size
                or byte_size > self._region_size - offset
            ):
                raise Error("Native view exceeds its retained allocation")

    def at(self, address: UInt) -> Self:
        var result = self.copy()
        result._address = address
        return result^

    def __eq__(self, other: Self) -> Bool:
        return self._address == other._address


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

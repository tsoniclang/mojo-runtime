from std.memory import Pointer
from std.testing import assert_equal

from tsonic_runtime import RawPointer, equal_raw_pointer, hash_raw_pointer


def main() raises:
    var first = Int32(7)
    var second = Int32(7)
    var address = Optional(RawPointer(UInt(Int(Pointer(to=first)))))
    var same_address = Optional(RawPointer(UInt(Int(Pointer(to=first)))))
    var other = Optional(RawPointer(UInt(Int(Pointer(to=second)))))
    var absent = Optional[RawPointer]()
    assert_equal(equal_raw_pointer(address, same_address), True)
    assert_equal(equal_raw_pointer(address, other), False)
    assert_equal(equal_raw_pointer(address, absent), False)
    assert_equal(equal_raw_pointer(absent, address), False)
    assert_equal(equal_raw_pointer(absent, absent), True)
    assert_equal(hash_raw_pointer(address), hash_raw_pointer(same_address))
    assert_equal(hash_raw_pointer(absent), Float64(0))

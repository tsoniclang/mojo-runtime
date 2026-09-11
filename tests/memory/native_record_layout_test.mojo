from std.memory import ArcPointer, Pointer
from std.testing import assert_equal
from tsonic_runtime import (
    RawPointer,
    reinterpret_location,
    to_raw_location,
    offset_raw_signed,
    require_native_field_count,
    require_native_field,
)


@fieldwise_init
struct Header(Copyable):
    var tag: UInt8
    var count: UInt32


def main() raises:
    require_native_field_count[Header, 2]()
    require_native_field[Header, UInt8, "tag", 0]()
    require_native_field[Header, UInt32, "count", 4]()
    var owner = ArcPointer(Header(3, 7))
    var raw = RawPointer.retained(owner, UInt(Int(owner.ptr())), 8)
    var record = reinterpret_location[Header, 8, 4, 8, 64, True](raw).value()
    assert_equal(record.read().tag, 3)
    record.write(Header(4, 11))
    assert_equal(owner[].tag, 4)
    assert_equal(owner[].count, 11)
    var field = reinterpret_location[UInt32, 4, 4, 4, 64, True](
        offset_raw_signed[64](raw, 4)
    ).value()
    field.write(19)
    assert_equal(record.read().count, 19)
    var raw_again = to_raw_location[Header, 8, 4, 8, 64, True](record)
    var field_again = reinterpret_location[UInt32, 4, 4, 4, 64, True](
        offset_raw_signed[64](raw_again, 4)
    ).value()
    field_again.write(23)
    assert_equal(owner[].count, 23)

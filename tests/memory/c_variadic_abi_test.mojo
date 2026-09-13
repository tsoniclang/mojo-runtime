from std.ffi import external_call
from std.testing import assert_equal


def main() raises:
    var buffer = List[UInt8]()
    for index in range(64):
        buffer.append(0)
    var format = "%d:%d:%.2f"
    var signed = Int8(-7)
    var unsigned = UInt8(250)
    var floating = Float32(1.5)
    var written = external_call["snprintf", Int32, num_fixed_args=3](
        buffer.unsafe_ptr(),
        UInt(64),
        format.as_c_string_slice(),
        Int32(signed),
        Int32(unsigned),
        Float64(floating),
    )
    var expected = "-7:250:1.50"
    assert_equal(Int(written), expected.byte_length())
    for index in range(expected.byte_length()):
        assert_equal(buffer[index], expected.as_bytes()[index])
    assert_equal(buffer[expected.byte_length()], UInt8(0))

from std import math


def source_number_to_uint32(value: Float64) -> UInt32:
    if not math.isfinite(value) or value == 0:
        return 0
    var remainder = math.trunc(value) % 4294967296.0
    if remainder < 0:
        remainder += 4294967296.0
    return UInt32(remainder)


def source_number_to_int32(value: Float64) -> Int32:
    var unsigned = Int64(source_number_to_uint32(value))
    if unsigned >= 2147483648:
        unsigned -= 4294967296
    return Int32(unsigned)


def source_number_bitwise_not(value: Float64) -> Float64:
    return Float64(~source_number_to_int32(value))


def source_number_bitwise_and(left: Float64, right: Float64) -> Float64:
    return Float64(source_number_to_int32(left) & source_number_to_int32(right))


def source_number_bitwise_or(left: Float64, right: Float64) -> Float64:
    return Float64(source_number_to_int32(left) | source_number_to_int32(right))


def source_number_bitwise_xor(left: Float64, right: Float64) -> Float64:
    return Float64(source_number_to_int32(left) ^ source_number_to_int32(right))


def source_number_shift_left(left: Float64, right: Float64) -> Float64:
    var count = Int32(source_number_to_uint32(right) & 31)
    return Float64(source_number_to_int32(left) << count)


def source_number_shift_right(left: Float64, right: Float64) -> Float64:
    var count = Int32(source_number_to_uint32(right) & 31)
    return Float64(source_number_to_int32(left) >> count)


def source_number_unsigned_shift_right(
    left: Float64, right: Float64
) -> Float64:
    var count = source_number_to_uint32(right) & 31
    return Float64(source_number_to_uint32(left) >> count)

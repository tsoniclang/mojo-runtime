from std.collections import Dict
from std.testing import assert_equal, assert_false, assert_true
from tsonic_runtime import BigInt, TsError
from tsonic_runtime.bigint import bigint_to_integer


def main() raises:
    var original = BigInt.from_decimal_literal(
        "1234567890123456789012345678901234567890"
    )
    var value = original.copy()
    value += 7
    assert_equal(String(value), "1234567890123456789012345678901234567897")
    assert_equal(String(original), "1234567890123456789012345678901234567890")
    assert_equal(String(value - original), "7")
    assert_equal(String(BigInt(-7) / BigInt(3)), "-2")
    assert_equal(String(BigInt(-7) % BigInt(3)), "-1")
    assert_equal(String(BigInt(7) % BigInt(-3)), "1")
    assert_equal(
        String(BigInt(2) ** BigInt(256)),
        "115792089237316195423570985008687907853269984665640564039457584007913129639936",
    )
    assert_equal(String(BigInt(8) << BigInt(-2)), "2")
    assert_equal(String(BigInt(-7) >> BigInt(1)), "-4")
    assert_equal(String(BigInt(3) >> BigInt(-2)), "12")
    assert_equal(String(~BigInt(0)), "-1")
    assert_equal(String(BigInt(-1) & BigInt(123)), "123")
    assert_equal(String(BigInt(8) | BigInt(3)), "11")
    assert_equal(String(BigInt(8) ^ BigInt(3)), "11")
    assert_true(original > BigInt(1))
    assert_false(BigInt(0))
    assert_true(BigInt(-1))
    var keys = Dict[BigInt, String]()
    keys[original.copy()] = "exact"
    assert_equal(
        keys[
            BigInt.from_decimal_literal(
                "1234567890123456789012345678901234567890"
            )
        ],
        "exact",
    )
    var caught = 0
    try:
        _ = BigInt(1) / BigInt(0)
    except exception:
        assert_equal(exception.name, "RangeError")
        caught += 1
    try:
        _ = BigInt(1) % BigInt(0)
    except exception:
        assert_equal(exception.name, "RangeError")
        caught += 1
    try:
        _ = BigInt(2) ** BigInt(-1)
    except exception:
        assert_equal(exception.name, "RangeError")
        caught += 1
    assert_equal(caught, 3)
    var maximum_count = BigInt.from_decimal_literal("18446744073709551615")
    try:
        _ = BigInt(2) ** maximum_count
    except exception:
        assert_equal(exception.name, "RangeError")
        caught += 1
    try:
        _ = BigInt(1) << maximum_count
    except exception:
        assert_equal(exception.name, "RangeError")
        caught += 1
    assert_equal(caught, 5)
    var huge = BigInt.from_decimal_literal(
        "99999999999999999999999999999999999999999999"
    )
    assert_equal(String(BigInt(-1) ** huge), "-1")
    assert_equal(String(BigInt(-7) >> huge), "-1")
    assert_equal(String(BigInt(0) << huge), "0")
    assert_equal(bigint_to_integer[Int8](BigInt(-128)), Int8(-128))
    assert_equal(bigint_to_integer[UInt8](BigInt(255)), UInt8(255))
    assert_equal(
        bigint_to_integer[Int64](BigInt(-9223372036854775808)),
        Int64(-9223372036854775808),
    )
    assert_equal(
        bigint_to_integer[UInt64](
            BigInt.from_decimal_literal("18446744073709551615")
        ),
        UInt64(18446744073709551615),
    )
    assert_equal(
        bigint_to_integer[Int128](
            BigInt.from_decimal_literal(
                "-170141183460469231731687303715884105728"
            )
        ),
        Int128(-170141183460469231731687303715884105728),
    )
    assert_equal(
        bigint_to_integer[UInt128](
            BigInt.from_decimal_literal(
                "340282366920938463463374607431768211455"
            )
        ),
        UInt128(340282366920938463463374607431768211455),
    )
    assert_equal(bigint_to_integer[Int](BigInt(-7)), -7)
    assert_equal(bigint_to_integer[UInt](BigInt(7)), UInt(7))
    var overflow = False
    try:
        _ = bigint_to_integer[UInt8](BigInt(-1))
    except:
        overflow = True
    assert_true(overflow)

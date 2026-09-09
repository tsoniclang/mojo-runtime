from std.testing import assert_equal
from tsonic_runtime.numeric import (
    SOURCE_MAX_SAFE_INTEGER,
    source_number_to_integer_or_infinity,
    source_number_to_length,
)


def main() raises:
    var positive = Float64(FloatLiteral.infinity)
    var negative = Float64(FloatLiteral.negative_infinity)
    var nan = Float64(FloatLiteral.nan)
    assert_equal(source_number_to_integer_or_infinity(nan), 0)
    assert_equal(source_number_to_integer_or_infinity(-0.0), 0)
    assert_equal(source_number_to_integer_or_infinity(1.9), 1)
    assert_equal(source_number_to_integer_or_infinity(-1.9), -1)
    assert_equal(source_number_to_integer_or_infinity(positive), positive)
    assert_equal(source_number_to_integer_or_infinity(negative), negative)
    assert_equal(source_number_to_integer_or_infinity(1e100), 1e100)
    assert_equal(source_number_to_length(nan), 0)
    assert_equal(source_number_to_length(negative), 0)
    assert_equal(source_number_to_length(-1.9), 0)
    assert_equal(source_number_to_length(3.9), 3)
    assert_equal(source_number_to_length(positive), SOURCE_MAX_SAFE_INTEGER)
    assert_equal(source_number_to_length(1e100), SOURCE_MAX_SAFE_INTEGER)

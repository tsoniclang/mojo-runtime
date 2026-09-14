from std import math
from std.testing import assert_equal, assert_true
from tsonic_runtime.numeric import source_number_remainder


def main() raises:
    assert_equal(source_number_remainder(-5.0, 2.0), -1.0)
    assert_equal(source_number_remainder(5.0, -2.0), 1.0)
    assert_equal(source_number_remainder(-5.5, 2.0), -1.5)
    assert_equal(source_number_remainder(1e300, 3.0), 0.0)
    var infinity = Float64(FloatLiteral.infinity)
    var nan = Float64(FloatLiteral.nan)
    assert_equal(source_number_remainder(7.0, infinity), 7.0)
    assert_true(math.isnan(source_number_remainder(1.0, 0.0)))
    assert_true(math.isnan(source_number_remainder(infinity, 1.0)))
    assert_true(math.isnan(source_number_remainder(nan, 1.0)))
    assert_true(math.isnan(source_number_remainder(1.0, nan)))
    assert_equal(math.copysign(1.0, source_number_remainder(-0.0, 3.0)), -1.0)
    assert_equal(math.copysign(1.0, source_number_remainder(-6.0, 3.0)), -1.0)

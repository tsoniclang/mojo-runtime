from std.testing import assert_equal

from tsonic_runtime.number_string import (
    source_number_code_units,
    source_number_to_string,
)


def main() raises:
    var cases: List[Tuple[Float64, String]] = [
        (0.0, "0"),
        (-0.0, "0"),
        (1.0, "1"),
        (-1.0, "-1"),
        (0.5, "0.5"),
        (-0.5, "-0.5"),
        (1.23, "1.23"),
        (1704067200000.0, "1704067200000"),
        (0.000001, "0.000001"),
        (1e-7, "1e-7"),
        (100000000000000000000.0, "100000000000000000000"),
        (1e21, "1e+21"),
        (1e22, "1e+22"),
        (1.23456789e-7, "1.23456789e-7"),
        (1000000000000000100.0, "1000000000000000100"),
        (9007199254740991.0, "9007199254740991"),
        (-9007199254740991.0, "-9007199254740991"),
        (5e-324, "5e-324"),
        (1.7976931348623157e308, "1.7976931348623157e+308"),
        (1.0000000000000002, "1.0000000000000002"),
        (3.141592653589793, "3.141592653589793"),
        (Float64(FloatLiteral.nan), "NaN"),
        (Float64(FloatLiteral.infinity), "Infinity"),
        (Float64(FloatLiteral.negative_infinity), "-Infinity"),
    ]
    for sample in cases:
        assert_equal(source_number_to_string(sample[0]), sample[1])
        var bytes = source_number_code_units[DType.uint8](sample[0])
        var code_units = source_number_code_units[DType.uint16](sample[0])
        var expected = sample[1].as_bytes()
        assert_equal(len(bytes), len(expected))
        assert_equal(len(code_units), len(expected))
        for index in range(len(expected)):
            assert_equal(bytes[index], expected[index])
            assert_equal(code_units[index], UInt16(expected[index]))

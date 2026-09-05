from std.testing import assert_equal
from tsonic_runtime import source_string_length


def main() raises:
    assert_equal(source_string_length("plain"), 5.0)
    assert_equal(source_string_length("e\u0301"), 2.0)
    assert_equal(source_string_length("😀"), 2.0)

from std.testing import assert_equal
from tsonic_runtime import TsError


def main() raises:
    var error = TsError("TypeError", "invalid value")
    assert_equal(String(error), "TypeError: invalid value")
    assert_equal(String(error.native_error()), "TypeError: invalid value")

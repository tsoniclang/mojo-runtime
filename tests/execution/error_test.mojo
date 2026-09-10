from std.testing import assert_equal
from tsonic_runtime import TsError, error_new


def main() raises:
    var error = TsError("TypeError", "invalid value", None)
    assert_equal(String(error), "TypeError: invalid value")
    assert_equal(String(error.native_error()), "TypeError: invalid value")
    var empty = error_new()
    assert_equal(empty.name, "Error")
    assert_equal(empty.message, "")
    var selected = error_new("selected")
    assert_equal(selected.message, "selected")
    assert_equal(selected.stack, None)

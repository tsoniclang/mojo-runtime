from std.testing import assert_equal
from tsonic_runtime import Null, Undefined


def main() raises:
    assert_equal(String(Undefined()), "undefined")
    assert_equal(String(Null()), "null")
    assert_equal(Undefined(), Undefined())
    assert_equal(Null(), Null())

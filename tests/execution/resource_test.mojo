from std.testing import assert_equal
from tsonic_runtime import suppressed_error


def main() raises:
    var error = suppressed_error(Error("cleanup"), Error("body"))
    assert_equal(String(error), "SuppressedError: cleanup; suppressed: body")

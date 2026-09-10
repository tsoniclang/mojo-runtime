from std.testing import assert_equal
from tsonic_runtime import StructuralObject


def main() raises:
    var value = StructuralObject((Int32(7), String("ready")))
    assert_equal(value._state[][0], 7)
    assert_equal(value._state[][1], "ready")

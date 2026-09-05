from std.testing import assert_equal, assert_false, assert_true
from tsonic_runtime import Location


def main() raises:
    var first = Location[Int32](41)
    var shared = first
    shared.write(42)
    assert_equal(first.read(), 42)
    assert_true(first.same_storage(shared))

    ref value = shared.borrow_mut()
    value += 1
    assert_equal(first.read(), 43)
    assert_equal(first.borrow(), 43)

    var independent = Location[Int32](42)
    assert_false(first.same_storage(independent))

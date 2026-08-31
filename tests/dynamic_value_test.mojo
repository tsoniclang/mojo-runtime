from std.testing import assert_equal, assert_true
from tsonic_runtime import Null, TsPrimitiveValue, Undefined


def main() raises:
    var value = TsPrimitiveValue(Int64(42))
    assert_true(value.isa[Int64]())
    assert_equal(value[Int64], 42)

    value.set[String]("value")
    assert_true(value.isa[String]())
    assert_equal(value[String], "value")

    value.set[Undefined](Undefined())
    assert_true(value.isa[Undefined]())

    value.set[Null](Null())
    assert_true(value.isa[Null]())

from std.testing import assert_equal
from tsonic_runtime import GlobalCell


@fieldwise_init
struct Counter:
    var value: Int


def create_counter() -> Counter:
    return Counter(40)


comptime counter = GlobalCell["tsonic.runtime.test.counter", create_counter]()


def main() raises:
    var first = counter.get()
    first[].value += 1

    var second = counter.get()
    second[].value += 1

    assert_equal(first[].value, 42)
    assert_equal(second[].value, 42)

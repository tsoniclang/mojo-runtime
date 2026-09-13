from std.testing import assert_equal, assert_true
from tsonic_runtime import (
    NativeArray,
    TypedLocation,
    reinterpret_location,
    to_raw_location,
)


def escaped() raises -> TypedLocation[UInt32]:
    var values = NativeArray[UInt32]([7, 8])
    var shared = values
    var pointer = values.location(1)
    pointer.write(12)
    assert_equal(shared[1], 12)
    shared[1] = 14
    assert_equal(pointer.read(), 14)
    assert_true(shared.location(1).same_storage(pointer))
    assert_true(not values.location(0).same_storage(pointer))
    values = NativeArray[UInt32]([21, 22])
    values[1] = 23
    assert_equal(pointer.read(), 14)
    return pointer


def main() raises:
    var pointer = escaped()
    assert_equal(pointer.read(), 14)
    var raw = to_raw_location[UInt32, 4, 4, 4, 64, True](pointer)
    var view = reinterpret_location[UInt32, 4, 4, 4, 64, True](raw).value()
    view.write(19)
    assert_equal(pointer.read(), 19)
    var empty = NativeArray[UInt32]([])
    var rejected = False
    try:
        _ = empty.location(0)
    except:
        rejected = True
    assert_true(rejected)

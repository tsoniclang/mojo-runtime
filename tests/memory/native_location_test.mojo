from std.memory import ArcPointer, Pointer
from std.testing import assert_equal, assert_true
from tsonic_runtime import (
    Location,
    RawPointer,
    TypedLocation,
    equal_raw_pointer,
    reinterpret_location,
    to_raw_location,
    offset_raw_signed,
    offset_raw_unsigned,
    raw_address,
    raw_from_address,
)


struct Region:
    var first: UInt32
    var second: UInt32
    var live: Location[Int]

    def __init__(out self, live: Location[Int]):
        self.first = 31
        self.second = 32
        self.live = live
        var counter = live
        counter.write(counter.read() + 1)

    def __deinit__(deinit self):
        var counter = self.live
        counter.write(counter.read() - 1)


def retained_view(live: Location[Int]) raises -> TypedLocation[UInt32]:
    var region = ArcPointer(Region(live))
    var address = UInt(Int(Pointer(to=region[].first)))
    var raw = RawPointer.retained(region, address, 8)
    var view = reinterpret_location[UInt32, 4, 4, 4, 64, True](
        raw.copy()
    ).value()
    view.write(39)
    assert_equal(region[].first, 39)
    var second = reinterpret_location[UInt32, 4, 4, 4, 64, True](
        offset_raw_signed[64](raw.copy(), 4)
    ).value()
    second.write(44)
    assert_equal(region[].second, 44)
    assert_true(
        equal_raw_pointer(
            to_raw_location[UInt32, 4, 4, 4, 64, True](view), raw.copy()
        )
    )
    var offsets: List[Int128] = [1, 8, -4]
    for offset in offsets:
        var rejected = False
        try:
            _ = reinterpret_location[UInt32, 4, 4, 4, 64, True](
                offset_raw_signed[64](raw.copy(), offset)
            )
        except:
            rejected = True
        assert_true(rejected)
    return view


def use_view(live: Location[Int]) raises:
    var view = retained_view(live)
    assert_equal(live.read(), 1)
    assert_equal(view.read(), 39)
    var aliases: List[TypedLocation[UInt32]] = [view]
    aliases[0].write(52)
    assert_equal(view.read(), 52)
    var raw = to_raw_location[UInt32, 4, 4, 4, 64, True](aliases[0])
    var round_trip = reinterpret_location[UInt32, 4, 4, 4, 64, True](
        raw
    ).value()
    assert_true(round_trip.same_storage(view))
    assert_equal(round_trip.identity.hash(), view.identity.hash())


def main() raises:
    var live = Location[Int](0)
    use_view(live)
    assert_equal(live.read(), 0)
    var cell = TypedLocation[UInt32](71)
    var raw = to_raw_location[UInt32, 4, 4, 4, 64, True](cell)
    var view = reinterpret_location[UInt32, 4, 4, 4, 64, True](raw).value()
    view.write(81)
    assert_equal(cell.read(), 81)
    assert_true(cell.same_storage(view))
    assert_true(not reinterpret_location[UInt32, 4, 4, 4, 64, True](None))
    assert_true(not to_raw_location[UInt32, 4, 4, 4, 64, True](None))
    var bits = UInt64(9007199254740993)
    var address = raw_from_address[64](bits)
    assert_equal(raw_address[64](offset_raw_signed[64](address, -4)), bits - 4)
    assert_equal(raw_address[64](offset_raw_unsigned[64](address, 4)), bits + 4)
    var offsets: List[Int128] = [-9007199254740994, Int128.MAX]
    for offset in offsets:
        var rejected = False
        try:
            _ = offset_raw_signed[64](address, offset)
        except:
            rejected = True
        assert_true(rejected)

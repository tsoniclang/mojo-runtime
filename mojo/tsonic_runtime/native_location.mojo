from std.memory import Pointer
from std.sys import size_of, align_of, is_little_endian
from .raw_pointer import RawPointer


@fieldwise_init
struct NativeLocation[T: Movable & Deinitable](ImplicitlyCopyable):
    var address: RawPointer

    def __init__(out self, *, copy: Self):
        self.address = copy.address.copy()

    def read(self) raises -> Self.T where conforms_to(Self.T, Copyable):
        self.address.require_region(
            UInt(size_of[Self.T]()), UInt(align_of[Self.T]())
        )
        var pointer = Pointer[mut=True, Self.T, MutUntrackedOrigin](
            unsafe_from_address=Int(self.address._address)
        )
        return pointer[].copy()

    def write(mut self, var value: Self.T) raises:
        self.address.require_region(
            UInt(size_of[Self.T]()), UInt(align_of[Self.T]())
        )
        var pointer = Pointer[mut=True, Self.T, MutUntrackedOrigin](
            unsafe_from_address=Int(self.address._address)
        )
        pointer[] = value^


def require_native_layout[
    T: AnyType,
    byte_size: Int,
    byte_alignment: Int,
    stride: Int,
    address_width: Int,
    little_endian: Bool,
]():
    comptime assert (
        byte_size == size_of[T]()
    ), "Selected memory size differs from the native carrier"
    comptime assert (
        byte_alignment == align_of[T]()
    ), "Selected memory alignment differs from the native carrier"
    comptime assert (
        stride == size_of[T]()
    ), "Selected memory stride differs from the native carrier"
    comptime assert (
        address_width == 8 * size_of[UInt]()
    ), "Selected address ABI differs from the native target"
    comptime assert (
        little_endian == is_little_endian()
    ), "Selected byte order differs from the native target"

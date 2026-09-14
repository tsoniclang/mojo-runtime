from std.ffi import external_call
from std.hashlib import Hasher
from std.memory import ArcPointer
from std.os import abort
from std.sys import bit_width_of
from .error import TsError


comptime _IntegerHandle = MutOpaquePointer[MutUntrackedOrigin]
comptime _OptionalIntegerHandle = OptionalPointer[NoneType, MutUntrackedOrigin]


@fieldwise_init
struct _IntegerStorage:
    var handle: _IntegerHandle

    def __deinit__(deinit self):
        external_call["tsonic_bigint_destroy", NoneType](self.handle)


struct BigInt(Boolable, Comparable, Hashable, ImplicitlyCopyable, Writable):
    var _storage: ArcPointer[_IntegerStorage]

    def __init__(out self):
        self = Self(0)

    @implicit
    def __init__(out self, value: IntLiteral[_]):
        comptime literal = IntLiteral[value.value]()
        comptime assert (
            literal >= -9223372036854775808 and literal <= 9223372036854775807
        ), "Use from_decimal_literal for arbitrary-precision literals"
        self = Self.from_decimal_literal(String(value))

    @staticmethod
    def from_decimal_literal(var digits: String) -> Self:
        var handle = external_call[
            "tsonic_bigint_parse", _OptionalIntegerHandle
        ](digits.as_c_string_slice().ptr())
        if not handle:
            abort("A checked integer literal must be valid")
        return Self(handle=handle.value())

    def __init__(out self, *, handle: _IntegerHandle):
        self._storage = ArcPointer(_IntegerStorage(handle))

    def __bool__(self) -> Bool:
        return (
            external_call["tsonic_bigint_sign", Int32](self._storage[].handle)
            != 0
        )

    def _compare(self, other: Self) -> Int32:
        return external_call["tsonic_bigint_compare", Int32](
            self._storage[].handle, other._storage[].handle
        )

    def __eq__(self, other: Self) -> Bool:
        return self._compare(other) == 0

    def __ne__(self, other: Self) -> Bool:
        return self._compare(other) != 0

    def __lt__(self, other: Self) -> Bool:
        return self._compare(other) < 0

    def __le__(self, other: Self) -> Bool:
        return self._compare(other) <= 0

    def __gt__(self, other: Self) -> Bool:
        return self._compare(other) > 0

    def __ge__(self, other: Self) -> Bool:
        return self._compare(other) >= 0

    def __hash__[H: Hasher](self, mut hasher: H):
        String(self).__hash__(hasher)

    def write_to(self, mut writer: Some[Writer]):
        var digits = external_call[
            "tsonic_bigint_digits", MutPointer[Int8, MutUntrackedOrigin]
        ](self._storage[].handle)
        var value = String(unsafe_from_utf8_ptr=digits)
        external_call["tsonic_bigint_free_digits", NoneType](digits)
        writer.write(value)

    def _binary[name: StaticString](self, other: Self) -> Self:
        return Self(
            handle=external_call[name, _IntegerHandle](
                self._storage[].handle, other._storage[].handle
            )
        )

    def _checked_binary[
        name: StaticString
    ](self, other: Self, message: String) raises TsError -> Self:
        var handle = external_call[name, _OptionalIntegerHandle](
            self._storage[].handle, other._storage[].handle
        )
        if not handle:
            raise TsError("RangeError", message, None)
        return Self(handle=handle.value())

    def __add__(self, other: Self) -> Self:
        return self._binary["tsonic_bigint_add"](other)

    def __sub__(self, other: Self) -> Self:
        return self._binary["tsonic_bigint_subtract"](other)

    def __mul__(self, other: Self) -> Self:
        return self._binary["tsonic_bigint_multiply"](other)

    def __truediv__(self, other: Self) raises TsError -> Self:
        return self._checked_binary["tsonic_bigint_divide"](
            other, "Division by zero"
        )

    def __mod__(self, other: Self) raises TsError -> Self:
        return self._checked_binary["tsonic_bigint_remainder"](
            other, "Division by zero"
        )

    def __pow__(self, other: Self) raises TsError -> Self:
        return self._checked_binary["tsonic_bigint_power"](
            other, "Exponent must be nonnegative and result size representable"
        )

    def __and__(self, other: Self) -> Self:
        return self._binary["tsonic_bigint_and"](other)

    def __or__(self, other: Self) -> Self:
        return self._binary["tsonic_bigint_or"](other)

    def __xor__(self, other: Self) -> Self:
        return self._binary["tsonic_bigint_xor"](other)

    def __lshift__(self, other: Self) raises TsError -> Self:
        return self._checked_binary["tsonic_bigint_shift_left"](
            other, "Bigint result size is not representable"
        )

    def __rshift__(self, other: Self) raises TsError -> Self:
        return self._checked_binary["tsonic_bigint_shift_right"](
            other, "Bigint result size is not representable"
        )

    def __neg__(self) -> Self:
        return Self(
            handle=external_call["tsonic_bigint_negate", _IntegerHandle](
                self._storage[].handle
            )
        )

    def __invert__(self) -> Self:
        return Self(
            handle=external_call["tsonic_bigint_invert", _IntegerHandle](
                self._storage[].handle
            )
        )

    def __iadd__(mut self, other: Self):
        self = self + other

    def __isub__(mut self, other: Self):
        self = self - other

    def __imul__(mut self, other: Self):
        self = self * other

    def __itruediv__(mut self, other: Self) raises TsError:
        self = self / other

    def __imod__(mut self, other: Self) raises TsError:
        self = self % other

    def __ipow__(mut self, other: Self) raises TsError:
        self = self**other

    def __iand__(mut self, other: Self):
        self = self & other

    def __ior__(mut self, other: Self):
        self = self | other

    def __ixor__(mut self, other: Self):
        self = self ^ other

    def __ilshift__(mut self, other: Self) raises TsError:
        self = self << other

    def __irshift__(mut self, other: Self) raises TsError:
        self = self >> other


comptime _IntegerDType[T: AnyType]: DType = (
    DType.int8 if T
    == Int8 else DType.uint8 if T
    == UInt8 else DType.int16 if T
    == Int16 else DType.uint16 if T
    == UInt16 else DType.int32 if T
    == Int32 else DType.uint32 if T
    == UInt32 else DType.int64 if T
    == Int64
    or T == Int else DType.uint64 if T == UInt64
    or T
    == UInt else DType.int128 if T
    == Int128 else DType.uint128 if T
    == UInt128 else DType.bool
)


def bigint_to_integer[T: ImplicitlyCopyable](value: BigInt) raises -> T:
    comptime dtype = _IntegerDType[T]
    comptime assert (
        dtype != DType.bool
    ), "An exact native integer type is required"
    var lower = UInt64(0)
    var upper = UInt64(0)
    var valid = external_call["tsonic_bigint_export", Int32](
        value._storage[].handle,
        Int32(bit_width_of[SIMD[dtype, 1]]()),
        Int32(dtype.is_signed()),
        MutPointer(to=lower),
        MutPointer(to=upper),
    )
    if valid == 0:
        raise Error("Bigint value is outside the selected native integer range")
    var packed = UInt128(lower) | (UInt128(upper) << 64)
    var result = SIMD[dtype, 1](packed)
    comptime if T == Int:
        return rebind[T](Int(result))
    elif T == UInt:
        return rebind[T](UInt(result))
    else:
        return rebind[T](result)

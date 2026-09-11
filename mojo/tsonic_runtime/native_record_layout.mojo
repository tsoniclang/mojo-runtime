from std.reflection import reflect


def require_native_field_count[T: AnyType, count: Int]():
    comptime assert (
        reflect[T].field_count() == count
    ), "Selected native layout does not cover every physical field"


def require_native_field[
    T: AnyType, Field: AnyType, name: StringLiteral, byte_offset: Int
]():
    comptime index = reflect[T].field_index[name]()
    comptime assert (
        reflect[T].field_types()[index] == Field
    ), "Selected field carrier differs from native storage"
    comptime assert (
        reflect[T].field_offset[name=name]() == byte_offset
    ), "Selected field offset differs from native storage"

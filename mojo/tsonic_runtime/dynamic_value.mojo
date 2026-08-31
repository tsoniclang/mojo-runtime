from std.utils import Variant

from .nullish import Null, Undefined


comptime TsPrimitiveValue = Variant[
    Undefined,
    Null,
    Bool,
    Int64,
    UInt64,
    Float64,
    String,
]

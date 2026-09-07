from std.collections import List, Span


def source_number_to_string(value: Float64) -> String:
    var units = source_number_code_units[DType.uint8](value)
    return String(unsafe_from_utf8=Span(units))


def source_number_code_units[dtype: DType](
    value: Float64
) -> List[SIMD[dtype, 1]]:
    comptime assert dtype == DType.uint8 or dtype == DType.uint16
    comptime Unit = SIMD[dtype, 1]
    if value != value:
        return _number_literal_units[dtype]("NaN")
    if value == Float64(FloatLiteral.infinity):
        return _number_literal_units[dtype]("Infinity")
    if value == Float64(FloatLiteral.negative_infinity):
        return _number_literal_units[dtype]("-Infinity")
    if value == 0:
        return _number_literal_units[dtype]("0")
    var source = String(value)
    var bytes = source.as_bytes()
    var offset = 0
    var negative = False
    if bytes[0] == Byte(45):
        negative = True
        offset = 1
    var exponent_offset = source.byte_length()
    for index in range(offset, source.byte_length()):
        if bytes[index] == Byte(101):
            exponent_offset = index
            break
    var digits = List[Unit]()
    var digits_before_decimal = 0
    var saw_decimal = False
    for index in range(offset, exponent_offset):
        if bytes[index] == Byte(46):
            digits_before_decimal = len(digits)
            saw_decimal = True
        else:
            digits.append(Unit(bytes[index]))
    if not saw_decimal:
        digits_before_decimal = len(digits)
    var source_exponent = 0
    if exponent_offset < source.byte_length():
        var index = exponent_offset + 1
        var exponent_negative = False
        if bytes[index] == Byte(43) or bytes[index] == Byte(45):
            exponent_negative = bytes[index] == Byte(45)
            index += 1
        while index < source.byte_length():
            source_exponent = source_exponent * 10 + Int(
                UInt8(bytes[index]) - 48
            )
            index += 1
        if exponent_negative:
            source_exponent = -source_exponent
    var leading = 0
    while leading < len(digits) and digits[leading] == 48:
        leading += 1
    var decimal_exponent = digits_before_decimal - leading - 1 + source_exponent
    var significant = List[Unit]()
    for index in range(leading, len(digits)):
        significant.append(digits[index])
    while len(significant) > 1 and significant[len(significant) - 1] == 48:
        _ = significant.pop()
    var result = List[Unit]()
    if negative:
        result.append(45)
    if decimal_exponent >= 21 or decimal_exponent <= -7:
        result.append(significant[0])
        if len(significant) > 1:
            result.append(46)
            for index in range(1, len(significant)):
                result.append(significant[index])
        result.append(101)
        result.append(Unit(43 if decimal_exponent >= 0 else 45))
        var exponent = String(abs(decimal_exponent))
        for digit in exponent.as_bytes():
            result.append(Unit(digit))
    elif decimal_exponent < 0:
        result.append(48)
        result.append(46)
        for _ in range(-decimal_exponent - 1):
            result.append(48)
        for digit in significant:
            result.append(digit)
    else:
        var integer_digits = decimal_exponent + 1
        for index in range(integer_digits):
            result.append(
                significant[index] if index < len(significant) else Unit(48)
            )
        if integer_digits < len(significant):
            result.append(46)
            for index in range(integer_digits, len(significant)):
                result.append(significant[index])
    return result^


def _number_literal_units[dtype: DType](
    value: StaticString
) -> List[SIMD[dtype, 1]]:
    var result = List[SIMD[dtype, 1]](capacity=value.byte_length())
    for byte in value.as_bytes():
        result.append(SIMD[dtype, 1](byte))
    return result^

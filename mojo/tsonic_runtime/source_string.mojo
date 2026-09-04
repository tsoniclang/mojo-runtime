def source_string_length(value: String) -> Float64:
    var length = 0
    for codepoint in value.codepoints():
        length += 1 if codepoint.to_u32() <= 0xFFFF else 2
    return Float64(length)

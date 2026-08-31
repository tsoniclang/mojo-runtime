struct Undefined(Equatable, ImplicitlyCopyable, Writable):
    def __init__(out self):
        pass

    def __eq__(self, other: Self) -> Bool:
        return True

    def write_to(self, mut writer: Some[Writer]):
        writer.write("undefined")


struct Null(Equatable, ImplicitlyCopyable, Writable):
    def __init__(out self):
        pass

    def __eq__(self, other: Self) -> Bool:
        return True

    def write_to(self, mut writer: Some[Writer]):
        writer.write("null")

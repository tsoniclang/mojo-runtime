@fieldwise_init
struct TsError(Copyable, Writable):
    var name: String
    var message: String
    var stack: Optional[String]

    def write_to(self, mut writer: Some[Writer]):
        writer.write(self.name, ": ", self.message)

    def native_error(self) -> Error:
        return Error(self.name, ": ", self.message)


def error_new() -> TsError:
    return TsError("Error", "", None)


def error_new(message: String) -> TsError:
    return TsError("Error", message, None)

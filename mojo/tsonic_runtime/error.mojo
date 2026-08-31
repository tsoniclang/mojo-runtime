@fieldwise_init
struct TsError(Copyable, Writable):
    var name: String
    var message: String

    def write_to(self, mut writer: Some[Writer]):
        writer.write(self.name, ": ", self.message)

    def native_error(self) -> Error:
        return Error(self.name, ": ", self.message)

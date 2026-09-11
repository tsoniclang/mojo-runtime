from std.memory import ArcPointer


@fieldwise_init
struct LocationIdentity(Equatable, ImplicitlyCopyable):
    var root: UInt
    var path: String

    def __eq__(self, other: Self) -> Bool:
        return self.root == other.root and self.path == other.path

    def member(self, key: String) -> Self:
        return Self(
            self.root, self.path + "m" + String(key.byte_length()) + ":" + key
        )

    def index(self, index: Int) -> Self:
        return Self(self.root, self.path + "i" + String(index) + ";")

    def hash(self) -> Float64:
        var value = UInt32(self.root) ^ UInt32(self.root >> 32)
        for byte in self.path.as_bytes():
            value = (value ^ UInt32(byte)) * UInt32(16777619)
        return Float64(value)


def location_identity[
    Owner: Movable & Deinitable
](owner: ArcPointer[Owner]) -> LocationIdentity:
    return LocationIdentity(UInt(Int(owner.ptr())), "")

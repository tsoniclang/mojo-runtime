from .project_object import ProjectObject


struct SharedReference(ImplicitlyCopyable):
    var _object: ProjectObject

    def __init__[T: Movable & Deinitable](out self, var value: T):
        self._object = ProjectObject(value^)

    def state[
        T: AnyType
    ](ref self) -> ref[origin_of(self._object).unsafe_mut_cast[True]()] T:
        return self._object.state[T]()

    def __is__(self, other: Self) -> Bool:
        return self._object.same(other._object)

    def identity_address(self) -> UInt:
        return self._object.identity_address()

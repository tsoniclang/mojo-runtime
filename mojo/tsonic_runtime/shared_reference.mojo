from .project_object import ProjectObject


struct SharedReference[T: AnyType](ImplicitlyCopyable):
    var _object: ProjectObject

    def __init__[
        _T: Movable & Deinitable
    ](out self: SharedReference[_T], var value: _T,):
        self._object = ProjectObject(value^)

    def __getitem__(
        ref self,
    ) -> ref[origin_of(self._object).unsafe_mut_cast[True]()] Self.T:
        return self._object.state[Self.T]()

    def __is__(self, other: Self) -> Bool:
        return self._object.same(other._object)

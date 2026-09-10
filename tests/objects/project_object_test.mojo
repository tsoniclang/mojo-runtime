from std.collections import Optional
from std.testing import assert_equal, assert_false
from tsonic_runtime import (
    ProjectObject,
    erase_project_view,
    restore_project_view,
)


@fieldwise_init
struct ProjectView(ImplicitlyCopyable):
    var value: Int32


def main() raises:
    var object = ProjectObject(Int32(7))
    var copy = object
    assert_equal(copy.state[Int32](), 7)

    var erased = erase_project_view(ProjectView(42))
    var restored = restore_project_view[ProjectView](Optional(erased))
    assert_equal(restored.value().value, 42)
    assert_false(restore_project_view[ProjectView](None))

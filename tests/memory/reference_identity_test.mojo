from std.memory import ArcPointer
from std.testing import assert_equal, assert_true, assert_false
from tsonic_runtime import (
    ProjectObject,
    SharedReference,
    StructuralObject,
    WeakReferenceIdentity,
)


def dropped() -> WeakReferenceIdentity:
    var owner = ArcPointer(42)
    return WeakReferenceIdentity(owner)


def dropped_project() -> WeakReferenceIdentity:
    var owner = ProjectObject(String("owned"))
    return owner.weak_identity()


def dropped_structural() -> WeakReferenceIdentity:
    var owner = StructuralObject[Tuple[Int]]((42,))
    return owner.weak_identity()


def retained_alias() -> Tuple[ArcPointer[Int], WeakReferenceIdentity]:
    var owner = ArcPointer(42)
    var retained_alias = owner
    return (retained_alias, WeakReferenceIdentity(owner))


def main() raises:
    var owner = ArcPointer(42)
    var first = WeakReferenceIdentity(owner)
    var second = WeakReferenceIdentity(owner)
    assert_true(first.same(second))
    assert_true(first.is_alive())
    assert_equal(first.address, UInt(Int(owner.ptr())))
    var different = ArcPointer(42)
    assert_false(first.same(WeakReferenceIdentity(different)))
    assert_false(dropped().is_alive())
    assert_false(dropped_project().is_alive())
    assert_false(dropped_structural().is_alive())
    var retained = retained_alias()
    assert_true(retained[1].is_alive())
    assert_equal(retained[0][], 42)
    var project = ProjectObject(42)
    assert_equal(project.identity_address(), project.weak_identity().address)
    var shared = SharedReference(42)
    assert_equal(shared.identity_address(), shared.weak_identity().address)
    var structural = StructuralObject[Tuple[Int]]((42,))
    assert_true(structural.weak_identity().same(structural.weak_identity()))
    assert_equal(structural._state[][0], 42)

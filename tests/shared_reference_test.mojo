from std.collections import Optional
from std.testing import assert_equal, assert_true
from std.utils import Variant
from tsonic_runtime import SharedReference


struct RecursiveState:
    var value: Int32
    var next: Optional[RecursiveValue]

    def __init__(out self, value: Int32, next: Optional[RecursiveValue]):
        self.value = value
        self.next = next


struct RecursiveValue(ImplicitlyCopyable):
    var _state: SharedReference

    def __init__(out self, value: Int32, next: Optional[RecursiveValue]):
        self._state = SharedReference(RecursiveState(value, next))

    def __is__(self, other: Self) -> Bool:
        return self._state is other._state


def require_copyable[T: Copyable & Deinitable](value: T):
    pass


@fieldwise_init
struct Leaf(ImplicitlyCopyable):
    var value: Int32


struct UnionRecursiveState:
    var child: Optional[Variant[UnionRecursiveValue, Leaf]]

    def __init__(out self, child: Optional[Variant[UnionRecursiveValue, Leaf]]):
        self.child = child


struct UnionRecursiveValue(ImplicitlyCopyable):
    var _state: SharedReference

    def __init__(
        out self,
        child: Optional[Variant[UnionRecursiveValue, Leaf]],
    ):
        self._state = SharedReference(UnionRecursiveState(child))


def main() raises:
    var tail = RecursiveValue(2, Optional[RecursiveValue]())
    var head = RecursiveValue(1, Optional(tail))
    var shared = head
    assert_true(head is shared)
    assert_equal(head._state.state[RecursiveState]().value, 1)
    assert_equal(
        head._state.state[RecursiveState]().next.value()._state.state[
            RecursiveState
        ]().value,
        2,
    )
    require_copyable(head)
    var leaf = Variant[UnionRecursiveValue, Leaf](Leaf(3))
    require_copyable(leaf)

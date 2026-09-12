# Mojo Runtime

Source-number formatting uses the pinned C++17 standard library's shortest
round-trip conversion through a bounded C ABI, then applies source decimal and
exponent notation. It does not use native Mojo Float64 display formatting as
semantic evidence. The runtime manifest declares the native unit and compiler
dependency; generated and user-owned Mojo builds consume the same contract.

Target-native runtime support for Mojo emitted by Tsonic.

The native profile uses Mojo values directly. This package contains only
semantic carriers that cannot be represented by ordinary Mojo syntax alone.

Retained native async callbacks use `make_async_callable` with the same `Callable`
and `ClosedRaisingCoroutine` carriers as other native calls. Each invocation owns
its argument tuple and a strong reference to the original captured environment.
Its synchronous start function must transfer the invocation to exactly one
native coroutine; that coroutine must call `take_async_invocation` exactly once
at entry and retain the returned owner through completion. The native coroutine
is linear: callers must consume it, including on exceptional paths. This does
not introduce another scheduler, copy captured state, or execute the body early.

## Development

```bash
npm test
```

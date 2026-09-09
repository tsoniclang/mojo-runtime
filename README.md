# Mojo Runtime

Source-number formatting uses the pinned C++17 standard library's shortest
round-trip conversion through a bounded C ABI, then applies source decimal and
exponent notation. It does not use native Mojo Float64 display formatting as
semantic evidence. The runtime manifest declares the native unit and compiler
dependency; generated and user-owned Mojo builds consume the same contract.

Target-native runtime support for Mojo emitted by Tsonic.

The native profile uses Mojo values directly. This package contains only
semantic carriers that cannot be represented by ordinary Mojo syntax alone.

## Development

```bash
npm test
```

#!/usr/bin/env bash
set -euo pipefail

PIXI_BIN="${PIXI_BIN:-pixi}"

"${PIXI_BIN}" run mojo format --quiet mojo tests
git diff --exit-code -- mojo tests

native_object="$("${PIXI_BIN}" run bash scripts/build-native.sh)"

failed=0
for test_file in tests/*.mojo; do
  if "${PIXI_BIN}" run mojo run -I mojo -Xlinker "$native_object" -Xlinker -lstdc++ "${test_file}"; then
    printf 'PASS %s\n' "$test_file"
  else
    printf 'FAIL %s\n' "$test_file"
    failed=1
  fi
done
exit "$failed"

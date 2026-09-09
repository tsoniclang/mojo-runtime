#!/usr/bin/env bash
set -euo pipefail

PIXI_BIN="${PIXI_BIN:-pixi}"

"${PIXI_BIN}" run mojo format --quiet mojo tests
git diff --exit-code -- mojo tests

native_object="$("${PIXI_BIN}" run bash scripts/build-native.sh)"
native_build=".temp/native-tests"
mkdir -p "$native_build"

failed=0
for test_file in tests/*.mojo; do
  test_name="$(basename "$test_file" .mojo)"
  if "${PIXI_BIN}" run mojo build -j 2 -I mojo -Xlinker "$native_object" -Xlinker -lstdc++ \
    "$test_file" -o "$native_build/$test_name" && "$native_build/$test_name"; then
    printf 'PASS %s\n' "$test_file"
  else
    printf 'FAIL %s\n' "$test_file"
    failed=1
  fi
done
exit "$failed"

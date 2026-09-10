#!/usr/bin/env bash
set -euo pipefail

PIXI_BIN="${PIXI_BIN:-pixi}"
BUILD_TIMEOUT="${MOJO_TEST_BUILD_TIMEOUT:-180s}"
RUN_TIMEOUT="${MOJO_TEST_RUN_TIMEOUT:-60s}"

"${PIXI_BIN}" run mojo format --quiet mojo tests
git diff --exit-code -- mojo tests

native_object="$("${PIXI_BIN}" run bash scripts/build-native.sh)"
native_build=".temp/native-tests"
mkdir -p "$native_build"

failed=0
test_inventory="$(find tests -type f -name '*.mojo' -print)"
if [[ -z "$test_inventory" ]]; then
  printf 'No native runtime proofs found\n' >&2
  exit 1
fi
mapfile -t test_files < <(printf '%s\n' "$test_inventory" | LC_ALL=C sort)
for test_file in "${test_files[@]}"; do
  test_name="${test_file#tests/}"
  test_name="${test_name%.mojo}"
  mkdir -p "$(dirname "$native_build/$test_name")"
  if timeout "$BUILD_TIMEOUT" "${PIXI_BIN}" run mojo build -j 2 -I mojo -Xlinker "$native_object" -Xlinker -lstdc++ \
    "$test_file" -o "$native_build/$test_name" && timeout "$RUN_TIMEOUT" "$native_build/$test_name"; then
    printf 'PASS %s\n' "$test_file"
  else
    printf 'FAIL %s\n' "$test_file"
    failed=1
  fi
done
exit "$failed"

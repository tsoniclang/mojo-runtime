#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output="$root/.temp/native-tests/number_string.o"
mkdir -p "$(dirname "$output")"
"${CONDA_PREFIX:?The pinned compiler environment must be active}/bin/g++" -O3 -fPIC -std=c++17 \
  -Wall -Wextra -Werror -c "$root/mojo/tsonic_runtime.native/number_string.cpp" -o "$output.$$.pending"
mv "$output.$$.pending" "$output"
printf '%s\n' "$output"

#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
prefix="${CONDA_PREFIX:?The pinned compiler environment must be active}"
manifest="$root/mojo/tsonic_runtime.runtime.json"
unit_text="$(node --input-type=module -e '
  import { readFileSync } from "node:fs";
  const manifest = JSON.parse(readFileSync(process.argv[1], "utf8"));
  for (const unit of manifest.translationUnits) {
    if (unit.language !== "c++" || unit.standard !== "c++17") {
      throw new Error("The core runtime native builder requires its declared C++17 units");
    }
    console.log(unit.path);
  }
' "$manifest")"
mapfile -t units <<<"$unit_text"
for unit in "${units[@]}"; do
  output="$root/.temp/native-tests/${unit%.cpp}.o"
  mkdir -p "$(dirname "$output")"
  "$prefix/bin/g++" -O3 -fPIC -std=c++17 -I"$prefix/include" \
    -Wall -Wextra -Werror -c "$root/mojo/$unit" -o "$output.$$.pending"
  mv "$output.$$.pending" "$output"
  printf '%s\n%s\n' -Xlinker "$output"
done
node --input-type=module -e '
  import { readFileSync } from "node:fs";
  import path from "node:path";
  const manifest = JSON.parse(readFileSync(process.argv[1], "utf8"));
  const prefix = process.argv[2];
  for (const library of manifest.staticLibraries) {
    console.log("-Xlinker");
    console.log(path.join(prefix, library));
  }
  console.log("-Xlinker");
  console.log(`-L${path.join(prefix, "lib")}`);
  for (const library of manifest.dynamicLibraries) {
    console.log("-Xlinker");
    console.log(`-l${library}`);
  }
' "$manifest" "$prefix"

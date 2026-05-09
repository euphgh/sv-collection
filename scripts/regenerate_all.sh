#!/usr/bin/env bash
#/** @brief Regenerates all files under libs/generated/.
#
# Iterates every array utility feature source in libs/ that declares
# a @gen:output directive and runs the generator for each one.
# Existing generated files are overwritten in place.
# */
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

feature_files=(
    libs/set_array_util.svh
    libs/aa_array_util.svh
    libs/aa_of_q_array_util.svh
    libs/aa_value_adapter_array_util.svh
)

for src in "${feature_files[@]}"; do
    printf 'Generating %s ...\n' "$src"
    python3 "$repo_root/scripts/generate_array_util.py" "$repo_root/$src"
done

printf 'Done.\n'

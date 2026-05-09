#!/usr/bin/env bash
#/** @brief Runs the full collection library verification suite.
#
# This script runs three verification phases:
# 1. Slang syntax check on each library source file.
# 2. Slang syntax check on each focused testbench (with package where needed).
# 3. VCS compile-and-run for each focused testbench and the package smoke test.
#
# Exit status is 0 only if every check and test passes.
# */
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

slang_common=(-I "$repo_root/libs" --std 1800-2017 --compat vcs)

lib_sources=(
    set_util.svh
    set_array_util.svh
    aa_util.svh
    aa_array_util.svh
    aa_of_q_util.svh
    aa_of_q_array_util.svh
    aa_value_adapter_util.svh
    aa_value_adapter_array_util.svh
)

testbenches=(
    set_util_tb.sv
    set_array_util_tb.sv
    aa_util_tb.sv
    aa_array_util_tb.sv
    aa_of_q_util_tb.sv
    aa_of_q_array_util_tb.sv
    aa_value_adapter_util_tb.sv
    aa_value_adapter_array_util_tb.sv
)

pkg_testbenches=(
    collection_smoke_tb.sv
)

pass=0
fail=0

record() {
    local label=$1 ok=$2
    if [[ "$ok" == "0" ]]; then
        printf '  PASS  %s\n' "$label"
        (( pass++ )) || true
    else
        printf '  FAIL  %s\n' "$label"
        (( fail++ )) || true
    fi
}

printf '=== Phase 1: Slang library syntax ===\n'
for src in "${lib_sources[@]}"; do
    if slang "${slang_common[@]}" "$repo_root/libs/$src" >/dev/null 2>&1; then
        record "slang $src" 0
    else
        record "slang $src" 1
    fi
done

printf '\n=== Phase 2: Slang testbench syntax ===\n'
for tb in "${testbenches[@]}"; do
    if slang "${slang_common[@]}" "$repo_root/tests/$tb" >/dev/null 2>&1; then
        record "slang $tb" 0
    else
        record "slang $tb" 1
    fi
done

for tb in "${pkg_testbenches[@]}"; do
    if slang "${slang_common[@]}" "$repo_root/libs/collection_pkg.sv" "$repo_root/tests/$tb" >/dev/null 2>&1; then
        record "slang $tb (with pkg)" 0
    else
        record "slang $tb (with pkg)" 1
    fi
done

printf '\n=== Phase 3: VCS compile + run ===\n'
if command -v vcs >/dev/null 2>&1; then
    for tb in "${testbenches[@]}" "${pkg_testbenches[@]}"; do
        if "$repo_root/scripts/run_vcs_tb.sh" "$repo_root/tests/$tb" >/dev/null 2>&1; then
            record "vcs $tb" 0
        else
            record "vcs $tb" 1
        fi
    done
else
    printf '  SKIP  vcs not found in PATH\n'
fi

printf '\n=== Summary: %d pass, %d fail ===\n' "$pass" "$fail"

if [[ "$fail" -gt 0 ]]; then
    exit 1
fi

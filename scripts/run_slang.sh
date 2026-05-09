#!/usr/bin/env bash
#/** @brief Runs slang syntax checks on library and testbench files.
#
# Phase 1 checks the package together with the smoke testbench using
# scripts/slang.f (which references filelist/lib.f and the strict warning
# flags).  Phase 2 checks each focused testbench individually using
# filelist/slang_tb.f (which carries the same warning flags but no library
# package, since focused testbenches `include utilities directly).
#
# Exit status is 0 only if every check passes.
# */
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

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

printf '=== Phase 1: Library + smoke test (package) ===\n'
if slang -f "$repo_root/scripts/slang.f" >/dev/null 2>&1; then
    record "slang lib+smoke" 0
else
    record "slang lib+smoke" 1
fi

printf '\n=== Phase 2: Focused testbench syntax ===\n'
while IFS= read -r tb; do
    [[ "$tb" =~ ^[[:space:]]*$ ]] && continue
    [[ "$tb" =~ ^# ]] && continue
    [[ "$tb" == tests/collection_smoke_tb.sv ]] && continue
    tb_name="$(basename "$tb")"
    if slang -f "$repo_root/filelist/slang_tb.f" "$repo_root/$tb" >/dev/null 2>&1; then
        record "slang $tb_name" 0
    else
        record "slang $tb_name" 1
    fi
done < "$repo_root/filelist/testbench.f"

printf '\n=== Summary: %d pass, %d fail ===\n' "$pass" "$fail"

if [[ "$fail" -gt 0 ]]; then
    exit 1
fi

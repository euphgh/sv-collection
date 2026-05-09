#!/usr/bin/env bash
#/** @brief Runs VCS compile-and-run for each testbench listed in filelist/testbench.f.
#
# Reads the testbench list from filelist/testbench.f.  Testbenches
# that `import collection::` are compiled with the library package;
# focused testbenches are compiled standalone with incdir only.
#
# Build artifacts are isolated under build/vcs/.
# Exit status is 0 only if every testbench passes.
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

compat_dir="$repo_root/build/vcs/.compat"
mkdir -p "$compat_dir"
if [[ ! -e "$compat_dir/libncursesw.so.5" ]]; then
    if [[ -e /lib/x86_64-linux-gnu/libncursesw.so.6 ]]; then
        ln -s /lib/x86_64-linux-gnu/libncursesw.so.6 "$compat_dir/libncursesw.so.5"
    fi
fi
export LD_LIBRARY_PATH="$compat_dir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

incdir="+incdir+$repo_root/libs+$repo_root/tests"

printf '=== VCS compile + run ===\n'
while IFS= read -r tb; do
    [[ "$tb" =~ ^[[:space:]]*$ ]] && continue
    [[ "$tb" =~ ^# ]] && continue
    tb_base="$(basename "$tb" .sv)"
    run_dir="$repo_root/build/vcs/$tb_base"
    mkdir -p "$run_dir"

    vcs_args=(-sverilog -full64 "$incdir")
    if grep -q 'import collection::' "$repo_root/$tb" 2>/dev/null; then
        vcs_args+=("$repo_root/libs/collection_pkg.sv")
    fi
    vcs_args+=("$repo_root/$tb")

    simv_name="simv_$tb_base"
    if ( cd "$run_dir" && vcs "${vcs_args[@]}" -o "$simv_name" >/dev/null 2>&1 \
         && "./$simv_name" >/dev/null 2>&1 ); then
        record "vcs $tb_base" 0
    else
        record "vcs $tb_base" 1
    fi
done < "$repo_root/filelist/testbench.f"

printf '\n=== Summary: %d pass, %d fail ===\n' "$pass" "$fail"

if [[ "$fail" -gt 0 ]]; then
    exit 1
fi

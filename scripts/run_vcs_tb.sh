#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
    printf 'Usage: %s <testbench.sv> [simv-name]\n' "${0##*/}" >&2
    exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

tb_path="$1"
shift

if [[ "$tb_path" = /* ]]; then
    tb_abs="$tb_path"
else
    tb_abs="$repo_root/$tb_path"
fi

if [[ ! -f "$tb_abs" ]]; then
    printf 'Testbench not found: %s\n' "$tb_abs" >&2
    exit 1
fi

tb_base="$(basename "$tb_abs" .sv)"
simv_name="${1:-simv_${tb_base}}"
if [[ $# -gt 0 ]]; then
    shift
fi

run_dir="$repo_root/build/vcs/$tb_base"
mkdir -p "$run_dir"

compat_dir="$repo_root/build/vcs/.compat"
mkdir -p "$compat_dir"

if [[ ! -e "$compat_dir/libncursesw.so.5" ]]; then
    if [[ -e /lib/x86_64-linux-gnu/libncursesw.so.6 ]]; then
        ln -s /lib/x86_64-linux-gnu/libncursesw.so.6 "$compat_dir/libncursesw.so.5"
    fi
fi

incdir_arg="+incdir+$repo_root/libs+$repo_root/tests"
export LD_LIBRARY_PATH="$compat_dir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

vcs_args=("$incdir_arg")

if grep -q 'import collection::' "$tb_abs" 2>/dev/null; then
    vcs_args+=("$repo_root/libs/collection_pkg.sv")
fi

vcs_args+=("$tb_abs")

(
    cd "$run_dir"
    vcs -sverilog -full64 "${vcs_args[@]}" -o "$simv_name"
    "./$simv_name" "$@"
)

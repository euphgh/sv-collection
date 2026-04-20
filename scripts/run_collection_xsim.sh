#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
LIB_DIR="$ROOT/libs"
BUILD_ROOT="$ROOT/build/xsim"
TOP="${1:-collection_smoke_tb}"
GUI_FLAG="${2:-}"
BUILD_DIR="$BUILD_ROOT/$TOP"
SNAPSHOT="${TOP}_sim"

mkdir -p "$BUILD_DIR"

pushd "$BUILD_DIR" >/dev/null

xvlog -sv "$LIB_DIR/collection_pkg.sv" -i "$LIB_DIR" "$ROOT"/tests/*.sv
xelab "work.$TOP" -debug typical -s "$SNAPSHOT"

if [[ "$GUI_FLAG" == "--gui" ]]; then
    xsim "$SNAPSHOT" -gui
else
    xsim "$SNAPSHOT" -R
fi

popd >/dev/null

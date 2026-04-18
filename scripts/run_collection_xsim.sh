#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
LIB_DIR="$ROOT/libs"
TEST_DIR="$ROOT/tests"
BUILD_DIR="$ROOT/build/xsim/collection_smoke"
SNAPSHOT="collection_smoke_tb_sim"

mkdir -p "$BUILD_DIR"

pushd "$BUILD_DIR" >/dev/null

xvlog -sv $LIB_DIR/collection_pkgs.sv -i "$LIB_DIR"
xvlog -sv "$TEST_DIR/collection_smoke_tb.sv"
xelab work.collection_smoke_tb -debug typical -s "$SNAPSHOT"

if [[ "${1:-}" == "--gui" ]]; then
    xsim "$SNAPSHOT" -gui
else
    xsim "$SNAPSHOT" -R
fi

popd >/dev/null

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
COLLECTION_DIR="$ROOT/libs"
TEST_DIR="$ROOT/tests"

slang -I "$COLLECTION_DIR" \
    "$COLLECTION_DIR/set_util.svh" \
    "$COLLECTION_DIR/aa_util.svh" \
    "$TEST_DIR/collection_smoke_tb.sv"

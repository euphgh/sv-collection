#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
pushd "$ROOT" > /dev/null

slang -f ./scripts/slang.f

# Collection Library

This repository contains a small SystemVerilog collection utility library.

The code is organized around reusable `*.svh` helpers under `libs/`, focused
testbenches under `tests/`, and high-level navigation pages under `docs/`.

## What Is Here

- `set_util`: queue-based set utilities
- `aa_util`: associative-array utilities for map-style containers
- `aa_of_q_util`: associative-array-of-queue utilities for multimap-style
  containers
- `aa_value_adapter_util`: bridge between `aa_of_q_t` and `aa_t`
- related array and multimap wrappers that build on the same collection model

## How To Use It

For focused VCS runs, use the helper script:

```bash
scripts/run_vcs_tb.sh tests/set_util_tb.sv
scripts/run_vcs_tb.sh tests/aa_util_tb.sv
scripts/run_vcs_tb.sh tests/aa_of_q_util_tb.sv
scripts/run_vcs_tb.sh tests/aa_value_adapter_util_tb.sv
```

The script keeps generated artifacts under `build/vcs/`.

For syntax checks, use the repository's lint flow in `scripts/slang.f` or the
targeted `slang` commands referenced in `AGENTS.md`.

## Where To Read Next

1. Read `AGENTS.md` for repository rules and workflow.
2. Read `docs/development_log.md` for shared toolchain notes and TODOs.
3. Read the feature pages in `docs/` to find the code and tests for each
   utility.
4. Read the source comments in `libs/` for the detailed API contracts.

## Docs Index

- `docs/set_util.md`
- `docs/aa_util.md`
- `docs/aa_of_q_util.md`
- `docs/aa_value_adapter_util.md`
- `docs/build_and_test.md`
- `docs/development_log.md`

## Repository Layout

- `libs/`: SystemVerilog utility code
- `tests/`: focused testbenches
- `docs/`: navigation pages and development notes
- `scripts/`: lint and VCS helpers
- `build/`: generated output location

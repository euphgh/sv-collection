# Testing Guide

## Directory Layout

- `libs/`
  Collection library sources
- `tests/`
  SystemVerilog testbenches
- `scripts/`
  Syntax-check and simulation scripts
- `docs/`
  Test plan and developer notes

## Available Testbenches

- `collection_smoke_tb.sv`
  Minimal end-to-end smoke coverage
- `set_util_tb.sv`
  Detailed coverage for all `set_util` APIs, including key-set equality
- `set_array_util_tb.sv`
  Detailed coverage for fixed-size array-of-set APIs, including per-bank union/intersect/diff
- `aa_util_tb.sv`
  Detailed coverage for all `aa_util` APIs, including key+value equality
- `aa_array_util_tb.sv`
  Detailed coverage for fixed-size array-of-aa APIs, excluding print-format verification
- `multimap_util_tb.sv`
  Detailed coverage for `aa of set` semantics, including total value counting and per-key set merge/intersect/diff
- `multimap_array_util_tb.sv`
  Detailed coverage for fixed-size array-of-multimap APIs, excluding print-format verification

## Running Slang Checks

Run all files listed in `filelist/lib.f` and `filelist/testbench.f`:

```bash
scripts/check_collection_core.sh
```

Check the native nested-associative-array `multimap_util` variant:

```bash
slang -D COLLECTION_USE_NESTED_AA_MULTIMAP -f scripts/slang.f
```

## Running XSim

Run the default smoke test:

```bash
scripts/run_collection_xsim.sh
```

Run a specific top-level testbench:

```bash
scripts/run_collection_xsim.sh set_util_tb
scripts/run_collection_xsim.sh set_array_util_tb
scripts/run_collection_xsim.sh aa_util_tb
scripts/run_collection_xsim.sh aa_array_util_tb
scripts/run_collection_xsim.sh multimap_util_tb
scripts/run_collection_xsim.sh multimap_array_util_tb
```

Open a specific test in GUI mode:

```bash
scripts/run_collection_xsim.sh aa_util_tb --gui
```

## Expected Output

Passing tests print one of:

```text
collection_smoke_tb: PASS
set_util_tb: PASS
set_array_util_tb: PASS
aa_util_tb: PASS
aa_array_util_tb: PASS
multimap_util_tb: PASS
multimap_array_util_tb: PASS
```

Failures stop immediately using `$fatal(1)` after printing a descriptive message.

## Notes For Future Tests

- Prefer one focused testbench per utility or container type
- Keep checks local and explicit; avoid hidden scoreboard logic for small library tests
- `multimap_util.svh` currently has two implementations in the same file:
  - default XSim-compatible bucket path
  - macro-enabled nested-AA path for tools that support nested associative arrays better
- When adding APIs, update both:
  - `docs/test-plan.md`
  - `filelist/testbench.f`

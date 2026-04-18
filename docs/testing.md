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
- `aa_util_tb.sv`
  Detailed coverage for all `aa_util` APIs, including key+value equality

## Running Slang Checks

Run all files listed in `filelist/lib.f` and `filelist/testbench.f`:

```bash
scripts/check_collection_core.sh
```

## Running XSim

Run the default smoke test:

```bash
scripts/run_collection_xsim.sh
```

Run a specific top-level testbench:

```bash
scripts/run_collection_xsim.sh set_util_tb
scripts/run_collection_xsim.sh aa_util_tb
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
aa_util_tb: PASS
```

Failures stop immediately using `$fatal(1)` after printing a descriptive message.

## Notes For Future Tests

- Prefer one focused testbench per utility or container type
- Keep checks local and explicit; avoid hidden scoreboard logic for small library tests
- When adding APIs, update both:
  - `docs/test-plan.md`
  - `filelist/testbench.f`

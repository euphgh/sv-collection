# Build And Test Helpers

## Purpose

This page points readers to the repository's helper workflow for running focused
VCS testbench builds without polluting the git-managed source tree.

Detailed tool flags belong in the script itself. This page only explains what
the helper is for and how to invoke it.

## Script Location

- `scripts/run_vcs_tb.sh`

## What The Script Does

- compiles a single testbench with VCS
- runs the compiled simulation immediately
- places generated VCS artifacts under `build/vcs/<testbench-name>/`
- avoids leaving `csrc/`, `ucli.key`, `simv*`, or `*.daidir` artifacts in the
  repository root

## Typical Usage

Run a focused testbench by passing the testbench source path:

```bash
scripts/run_vcs_tb.sh tests/set_util_tb.sv
```

Optionally provide a custom simulator executable name:

```bash
scripts/run_vcs_tb.sh tests/set_util_tb.sv my_simv
```

## Full Verification Suite

The `scripts/run_all_tests.sh` script runs the complete verification pipeline:

1. Slang syntax check on each library source file.
2. Slang syntax check on each focused testbench (with package where needed).
3. VCS compile-and-run for each focused testbench and the package smoke test.

```bash
scripts/run_all_tests.sh
```

Exit status is 0 only if every check and test passes.

## Package-Level Smoke Test

The `tests/collection_smoke_tb.sv` testbench imports all utilities through
`import collection::*` and validates core API behavior for each utility class.
It is the recommended integration test to run after changing shared
infrastructure such as the generator or the package file.

```bash
scripts/run_vcs_tb.sh tests/collection_smoke_tb.sv
```

## Where To Look Next

- read `scripts/run_vcs_tb.sh` for the exact invocation details
- read the target testbench under `tests/` for the specific test scope
- read `AGENTS.md` for repository rules about build artifacts and isolated
  testbench flows

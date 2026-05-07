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

## Where To Look Next

- read `scripts/run_vcs_tb.sh` for the exact invocation details
- read the target testbench under `tests/` for the specific test scope
- read `AGENTS.md` for repository rules about build artifacts and isolated
  testbench flows

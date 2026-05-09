# Build And Test Helpers

## Purpose

This page points readers to the repository's helper scripts for running slang
syntax checks and VCS testbench builds without polluting the git-managed source
tree.

Detailed tool flags belong in the scripts and filelists themselves. This page
only explains what each helper is for and how to invoke it.

## Filelists

- `filelist/lib.f`: library source files and include paths for slang
- `filelist/testbench.f`: all testbench source paths (used by both scripts)
- `filelist/slang_tb.f`: slang flags for focused testbench checks (same strict
  warnings as `scripts/slang.f`, but no library package)
- `scripts/slang.f`: full-project slang invocation (references lib.f, adds
  warning flags)

## Slang Syntax Check

- `scripts/run_slang.sh`

The script runs two phases:

1. **Library + smoke test**: uses `slang -f scripts/slang.f` to check the
   package and the `collection_smoke_tb` together.
2. **Focused testbenches**: checks each focused testbench individually using
   `slang -f filelist/slang_tb.f`, which carries the same strict warning flags
   but does not include the library package (focused testbenches `include
   utilities directly).

```bash
scripts/run_slang.sh
```

For a quick manual check of the full project:

```bash
slang -f scripts/slang.f
```

## VCS Compile And Run

- `scripts/run_vcs.sh`

The script iterates all testbenches listed in `filelist/testbench.f`.  For each
testbench it compiles with VCS, runs the simulation, and reports pass/fail.
Testbenches that `import collection::` are automatically compiled with the
library package; focused testbenches are compiled standalone with incdir only.

Build artifacts are isolated under `build/vcs/<testbench-name>/`.

```bash
scripts/run_vcs.sh
```

## Package-Level Smoke Test

The `tests/collection_smoke_tb.sv` testbench imports all utilities through
`import collection::*` and validates core API behavior for each utility class.
It is the recommended integration test to run after changing shared
infrastructure such as the generator or the package file.

```bash
scripts/run_vcs.sh
```

## Code Regeneration

- `scripts/regenerate_all.sh`

Runs `scripts/generate_array_util.py` for every array utility feature source
that has a `@gen:output` directive.  Overwrites all files under
`libs/generated/`.

```bash
scripts/regenerate_all.sh
```

Run this after editing array utility feature sources or the generator script
itself, then re-run the slang and VCS checks to verify.

## Where To Look Next

- read `scripts/run_slang.sh` and `scripts/run_vcs.sh` for exact invocation
  details
- read the filelists under `filelist/` for the source of truth on which files
  are compiled
- read the target testbench under `tests/` for the specific test scope
- read `AGENTS.md` for repository rules about build artifacts and isolated
  testbench flows

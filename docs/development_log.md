# Development Log

## Purpose

This page records repository-wide development notes that are useful across
multiple features.

Use it for recurring toolchain issues, shared implementation pitfalls, and TODO
items that should remain visible while the codebase evolves.

This file is not a feature spec. It is a short memory aid for future work.

## Current Notes

- VCS W-2024.09-SP1 has been observed to segfault on some out-of-block methods
  that return a nested class typedef directly, such as `aa_util::aa_t`.
- Prefer keeping the affected method inline or reshaping the return type when
  that pattern appears in new code.
- VCS runs should use `scripts/run_vcs.sh` so that artifacts stay
  under `build/vcs/`.

## Open TODOs

- Revisit any remaining out-of-block methods that use nested class typedefs in
  return position if VCS shows instability again.
- Keep high-level API guidance in `docs/` and detailed contracts in source
  comments.

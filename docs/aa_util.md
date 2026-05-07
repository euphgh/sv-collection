# `aa_util`

## What It Is

`aa_util` is the repository's associative-array utility for map-style
containers.

It is the code location to read when you want to understand how this project
builds collection behavior on top of a native SystemVerilog associative array.

This document is intentionally high level. Detailed API contracts, edge cases,
and per-argument semantics live in the source comments of `libs/aa_util.svh`.

## What Feature It Covers

This feature covers:

- a map-style container represented as `VAL_T[KEY_T]`
- key-level observation helpers
- value lookup helpers
- collection-style operations such as merge, intersect, and diff
- projection helpers for extracting key and value views

Current high-level status:

- `contains_keys` is kept as a user-facing helper for direct key-set checks
- `*_into()` uses append-into-result semantics
- `get_values()` returns a raw queue view and preserves repeated values

## Where To Read The Code

Start here:

- `libs/aa_util.svh`

Then read the focused testbench:

- `tests/aa_util_tb.sv`

If you are trying to understand how this utility is reused by larger
collection helpers, continue with:

- `libs/aa_array_util.svh`
- `libs/multimap_util.svh`
- `libs/aa_of_q_util.svh`

## Recommended Reading Order

For someone trying to understand this feature:

1. Read the class-level comment in `libs/aa_util.svh`.
2. Read the public API declarations in the class body.
3. Read the class-external function bodies and implementation notes.
4. Read `tests/aa_util_tb.sv` to see the intended scenarios and edge cases.

## How This File Fits In The Repository

`aa_util` is the map-style collection helper in `libs/`.

- `set_util.svh` defines the queue/set layer that `aa_util` reuses for key and
  value projections
- `aa_of_q_util.svh` builds a multimap-style layer on top of the same
  collection concepts
- higher-level helpers reuse `aa_util` rather than re-implementing map-style
  behavior

## Notes For Readers

- Use this `docs/` page for orientation only.
- Treat `libs/aa_util.svh` as the detailed API reference.
- Treat `tests/aa_util_tb.sv` as the executable view of the intended behavior.

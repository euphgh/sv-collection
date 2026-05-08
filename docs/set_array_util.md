# `set_array_util`

## What It Is

`set_array_util` is the repository's fixed-size array-of-set utility.

It models a container as `set_t set_array_t[SIZE]`, where each slot is an
independent set-like queue and cross-array operations are performed
pointwise by index.

This document is intentionally high level. Detailed API contracts, edge cases,
and parameter semantics belong in the source comments of
`libs/set_array_util.svh`.

## What Feature It Covers

This feature covers:

- a fixed-size `set_array_t[SIZE]` container
- elementwise equality and containment across arrays
- elementwise union, intersection, and difference
- per-slot delegation to `set_util`
- normalized set behavior inside each slot
- array-level print helpers for debugging each slot as one line

Current high-level status:

- the array shape is fixed at compile time through `SIZE`
- each slot is an independent `set_t`
- cross-array collection operations are pointwise; no slot reordering or
  cross-slot merging occurs
- `*_into()` follows `set_util`'s append-into-result behavior per slot and does
  not clear pre-existing content in `result[i]`
- `set_array_util` intentionally exposes a subset of `set_util`, not a slot-
  local wrapper over the full queue API
- print helpers are array-oriented and render one array element per line

## API Review

The intended API surface is intentionally small and array-oriented.

Keep:

- `typedef` aliases for the set element type and array type
- `equals`
- `contains`
- `union_into`, `get_union`, `union_with`
- `intersect_into`, `get_intersect`, `intersect_with`
- `diff_into`, `get_diff`, `diff_with`
- `print` / `sprint` helpers that format one array element per output line

Remove or do not add:

- slot-local CRUD wrappers such as `insert`, `delete`, `count`, and
  `unique_into`
- slot-local containment wrappers such as `contains_at`

Why:

- slot-local CRUD would turn this class into a thin per-slot forwarding layer
  rather than an array-level collection helper
- callers can still use native array indexing plus `set_util` when they need
  to manipulate a specific slot directly
- array-level printing is useful for debugging whole containers, while
  slot-local debug wrappers would add little value

## Print Format

The intended print format is row-based.

- each output line corresponds to one `set_array_t` element
- each line prints the slot index and the set stored in that slot
- the format is meant for debugging and inspection, not for round-tripping

## Where To Read The Code

Start here:

- `libs/set_array_util.svh`

Then read these dependencies:

- `libs/set_util.svh`
  queue/set behavior that each slot delegates to
- `libs/aa_array_util.svh`
  a closely related array-of-container pattern in this repository

Then read the focused testbench:

- `tests/set_array_util_tb.sv`

## Recommended Reading Order

For someone trying to understand this feature:

1. Read the class-level comment in `libs/set_array_util.svh`.
2. Read the public API declarations in the class body.
3. Read the class-external function bodies and implementation notes.
4. Read `tests/set_array_util_tb.sv` to see the intended behavior and edge
   cases.
5. Read `libs/set_util.svh` if you need the delegated slot semantics.

## How This File Fits In The Repository

`set_array_util` is the array-level companion to `set_util`.

- `set_util.svh` defines the per-slot queue/set behavior
- `set_array_util.svh` applies those semantics across a fixed-size array
- `aa_array_util.svh` shows the same design pattern for map-style containers

If you are changing slot-level set semantics, check `set_util.svh` first.
If you are changing array-level collection semantics, this is the main file to
change.

## Generator

The generated implementation for this feature is produced by
`scripts/generate_array_util.py`.

## Notes For Readers

- Use this `docs/` page for orientation, not for authoritative API details.
- Treat the source comments in `libs/set_array_util.svh` as the detailed
  contract.
- Treat the testbench as the executable view of the intended behavior.

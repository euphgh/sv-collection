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

Current high-level status:

- the array shape is fixed at compile time through `SIZE`
- each slot is an independent `set_t`
- cross-array collection operations are pointwise; no slot reordering or
  cross-slot merging occurs
- `*_into()` follows `set_util`'s append-into-result behavior per slot and does
  not clear pre-existing content in `result[i]`

## API Review

The intended API surface is intentionally small.

Keep:

- `typedef` aliases for the set element type and array type
- `equals`
- `contains`
- `union_into`, `get_union`, `union_with`
- `intersect_into`, `get_intersect`, `intersect_with`
- `diff_into`, `get_diff`, `diff_with`

Remove or do not add:

- slot-local CRUD wrappers such as `insert`, `delete`, and `count`
- slot-local containment wrappers such as `contains_at`
- debug-format helpers such as `sprint` and `print`

Why:

- slot-local CRUD is already expressible with native array indexing plus
  `set_util`
- debug printing can be done directly by callers when needed
- the class should stay focused on array-level collection semantics, not become
  a convenience wrapper for every slot operation

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

## Notes For Readers

- Use this `docs/` page for orientation, not for authoritative API details.
- Treat the source comments in `libs/set_array_util.svh` as the detailed
  contract.
- Treat the testbench as the executable view of the intended behavior.

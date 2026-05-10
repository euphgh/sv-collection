# `aa_array_util`

## What It Is

`aa_array_util` is the repository's fixed-size array-of-associative-array
utility.

It is the code location to read when you want to understand how the project
applies map-style associative-array behavior across a compile-time fixed set of
banks.

This document is intentionally high level. Detailed API contracts, edge cases,
and per-argument semantics live in the source comments of
`libs/aa_array_util.svh`.

## What Feature It Covers

This feature covers:

- a fixed-size `aa_t aa_array_t[SIZE]` container
- pointwise collection operations across array banks
- per-bank delegation to `aa_util`
- projection of per-bank key sets via `aa_util`
- row-based debug printing for whole array containers, delegating slot
  formatting to `elem_util::sprint` with `%x` formatting

Current high-level status:

- each array bank behaves like an independent associative array
- cross-array operations are applied bank by bank
- `*_into()` follows `aa_util` semantics within each bank and does not clear
  unrelated content in the destination bank
- key projection is bank-local and is obtained by calling `aa_util` on each bank
- print helpers are array-oriented and delegate bank formatting to
  `elem_util::sprint`, which uses `%x` for keys and values; non-empty banks
  show indented key=value lines under the bank index, empty banks show
  `(empty)`

## Where To Read The Code

Start here:

- `libs/aa_array_util.svh`

Then read these dependencies:

- `libs/aa_util.svh`
  map-style associative-array behavior delegated by each bank
- `libs/set_util.svh`
  queue/set semantics used by `aa_util` for key projections
- `libs/set_array_util.svh`
  a closely related fixed-size array utility with the same pointwise design

Then read the focused testbench:

- `tests/aa_array_util_tb.sv`

## Recommended Reading Order

For someone trying to understand this feature:

1. Read the class-level comment in `libs/aa_array_util.svh`.
2. Read the public API declarations in the class body.
3. Read the class-external function bodies and implementation notes.
4. Read `tests/aa_array_util_tb.sv` to see the intended behavior and edge
   cases.
5. Read `libs/aa_util.svh` if you need the delegated map semantics.

## How This File Fits In The Repository

`aa_array_util` is the fixed-size array companion to `aa_util`.

- `aa_util.svh` defines the per-map behavior
- `aa_array_util.svh` applies those semantics across a fixed-size array
- `set_array_util.svh` shows the same pointwise pattern for set containers

If a bank-local result can already be obtained directly from `aa_util` or plain
array indexing, `aa_array_util` should not add a wrapper for it.

## Generator

The generated implementation for this feature is produced by
`scripts/generate_array_util.py`.

If you are changing map-style associative-array semantics, check `aa_util.svh`
first.
If you are changing array-level collection semantics, this is the main file to
change.

## Notes For Readers

- Use this `docs/` page for orientation, not for authoritative API details.
- Treat the source comments in `libs/aa_array_util.svh` as the detailed
  contract.
- Treat the testbench as the executable view of the intended behavior.

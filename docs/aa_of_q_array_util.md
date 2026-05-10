# `aa_of_q_array_util`

## What It Is

`aa_of_q_array_util` is the repository's fixed-size array-of-multimap
utility.

It is the code location to read when you want to understand how the project
applies `aa_of_q_util` behavior across a compile-time fixed set of banks.

This document is intentionally high level. Detailed API contracts, edge cases,
and per-argument semantics live in the source comments of
`libs/aa_of_q_array_util.svh`.

## What Feature It Covers

This feature covers:

- a fixed-size `aa_of_q_t aa_of_q_array_t[SIZE]` container
- pointwise collection operations across array banks
- per-bank delegation to `aa_of_q_util`
- per-bank key-set and value-set projection APIs
- per-bank normalization helpers
- row-based debug printing for whole array containers, delegating bank
  formatting to `elem_util::sprint` with `%x` formatting

Current high-level status:

- each array bank behaves like an independent normalized multimap
- cross-array operations are applied bank by bank
- `*_into()` follows `aa_of_q_util` semantics within each bank and does not
  clear unrelated content in the destination bank
- `clean()` canonicalizes each bank by removing empty-queue keys
- key and value projection APIs are bank-local and are obtained by calling
  `aa_of_q_util` on each bank
- print helpers are array-oriented and delegate bank formatting to
  `elem_util::sprint`, which uses `%x` for keys and values; non-empty banks
  show indented `key: {values}` lines under the bank index, empty banks show
  `(empty)`

## Where To Read The Code

Start here:

- `libs/aa_of_q_array_util.svh`

Then read these dependencies:

- `libs/aa_of_q_util.svh`
  multimap behavior delegated by each bank
- `libs/set_util.svh`
  queue/set semantics used by `aa_of_q_util`
- `libs/aa_array_util.svh`
  a closely related fixed-size array utility with the same pointwise design

Then read the focused testbench:

- `tests/aa_of_q_array_util_tb.sv`

## Recommended Reading Order

For someone trying to understand this feature:

1. Read the class-level comment in `libs/aa_of_q_array_util.svh`.
2. Read the public API declarations in the class body.
3. Read the class-external function bodies and implementation notes.
4. Read `tests/aa_of_q_array_util_tb.sv` to see the intended behavior and edge
   cases.
5. Read `libs/aa_of_q_util.svh` if you need the delegated multimap semantics.

## How This File Fits In The Repository

`aa_of_q_array_util` is the array-level companion to `aa_of_q_util`.

- `aa_of_q_util.svh` defines the per-multimap behavior
- `aa_of_q_array_util.svh` applies those semantics across a fixed-size array
- `aa_array_util.svh` shows the same pointwise pattern for map-style
  containers

If you are changing multimap semantics, check `aa_of_q_util.svh` first.
If you are changing array-level collection semantics, this is the main file to
change.

## Notes For Readers

- Use this `docs/` page for orientation, not for authoritative API details.
- Treat the source comments in `libs/aa_of_q_array_util.svh` as the detailed
  contract.
- Treat the testbench as the executable view of the intended behavior.

# `aa_value_adapter_array_util`

## What It Is

`aa_value_adapter_array_util` is the repository's fixed-size array adapter between
scalar-map values and queue-valued multimap entries.

It is the code location to read when you want to apply `aa_value_adapter_util`
behavior across a compile-time fixed set of banks.

This document is intentionally high level. Detailed API contracts, edge cases,
and per-argument semantics live in the source comments of
`libs/aa_value_adapter_array_util.svh`.

## What Feature It Covers

This feature covers:

- a fixed-size array adapter between `aa_of_q_array_t` and `aa_array_t`
- pointwise containment, merge, intersect, and diff across array banks
- per-bank delegation to `aa_value_adapter_util`
- per-bank projection helpers between the two container shapes

Current high-level status:

- each array bank pair is an independent scalar-map / multimap pair
- cross-type operations are applied bank by bank
- `*_into()` follows `aa_value_adapter_util` semantics within each bank and
  does not clear unrelated content in the destination bank
- `to_aa()` projects each bank from multimap to scalar map
- `to_aa_of_q()` lifts each bank from scalar map to multimap

## Where To Read The Code

Start here:

- `libs/aa_value_adapter_array_util.svh`

Then read these dependencies:

- `libs/aa_value_adapter_util.svh`
  adapter behavior delegated by each bank
- `libs/aa_of_q_util.svh`
  multimap behavior that the adapter builds on
- `libs/aa_util.svh`
  scalar map shape that the adapter projects to and from
- `libs/set_util.svh`
  queue/set semantics used by `aa_of_q_util`

Then read the focused testbench:

- `tests/aa_value_adapter_array_util_tb.sv`

## Recommended Reading Order

For someone trying to understand this feature:

1. Read the class-level comment in `libs/aa_value_adapter_array_util.svh`.
2. Read the public API declarations in the class body.
3. Read the class-external function bodies and implementation notes.
4. Read `tests/aa_value_adapter_array_util_tb.sv` to see the intended behavior
   and edge cases.
5. Read `libs/aa_value_adapter_util.svh` if you need the delegated adapter
   semantics.

## How This File Fits In The Repository

`aa_value_adapter_array_util` is the array-level companion to
`aa_value_adapter_util`.

- `aa_value_adapter_util.svh` defines the per-bank adapter behavior
- `aa_value_adapter_array_util.svh` applies those semantics across a
  fixed-size array
- `aa_of_q_array_util.svh` shows the same pointwise pattern for homogeneous
  multimap containers

If you are changing adapter semantics, check `aa_value_adapter_util.svh` first.
If you are changing array-level adapter semantics, this is the main file to
change.

## Generator

The generated implementation for this feature is produced by
`scripts/generate_array_util.py`.

## Notes For Readers

- Use this `docs/` page for orientation, not for authoritative API details.
- Treat the source comments in `libs/aa_value_adapter_array_util.svh` as the
  detailed contract.
- Treat the testbench as the executable view of the intended behavior.

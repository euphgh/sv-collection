# `set_util`

## What It Is

`set_util` is the repository's queue-based set utility.

It is the code location to read when you want to understand how this project
builds set-style behavior on top of a native SystemVerilog queue.

This document is intentionally high level. Detailed API contracts, edge cases,
and parameter semantics belong in the source comments of `libs/set_util.svh`.

## What Feature It Covers

This feature covers:

- a set-style container represented as `KEY_T[$]`
- membership, equality, insertion, deletion, and counting helpers
- collection-style operations such as union, intersection, and difference
- behavior that depends on `UNIQUE_ELEM`
- an in-place normalization helper for turning a general queue into a
  set-shaped queue

Current high-level status:

- `UNIQUE_ELEM == 1` is the primary set-style mode
- `UNIQUE_ELEM == 0` currently supports the basic queue-oriented helpers and
  normalization flow; duplicate-sensitive collection semantics are intentionally
  deferred until that contract is finalized

## Where To Read The Code

Start here:

- `libs/set_util.svh`

Then read the focused testbench:

- `tests/set_util_tb.sv`

If you are trying to understand how this utility is reused by larger
collection helpers, continue with:

- `libs/aa_util.svh`
- `libs/aa_of_q_util.svh`
- `libs/set_array_util.svh`

## Recommended Reading Order

For someone trying to understand this feature:

1. Read the class-level comment in `libs/set_util.svh`.
2. Read the public API declarations in the class body.
3. Read the class-external function bodies and implementation notes.
4. Read `tests/set_util_tb.sv` to see the intended scenarios and edge cases.

## How This File Fits In The Repository

`set_util` is the lowest-level collection helper in `libs/`.

- it defines queue-level set behavior
- higher-level helpers build on it rather than re-implementing value semantics
- changes here can affect map-like and multimap-style utilities that delegate
  to it

## Notes For Readers

- Use this `docs/` page for orientation only.
- Treat `libs/set_util.svh` as the detailed API reference.
- Treat `tests/set_util_tb.sv` as the executable view of the intended behavior.

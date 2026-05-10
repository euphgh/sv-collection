# `aa_of_q_util`

## What It Is

`aa_of_q_util` is the repository's associative-array-of-queue utility.

It is the code location to read when you want to understand the project's
native `KEY_T -> VAL_T[$]` multimap-style container support.

This document is intentionally high level. Detailed API semantics, contracts,
and boundary conditions live in the source comments of
`libs/aa_of_q_util.svh`.

## What Feature It Covers

This feature covers:

- a multimap-style container built from a SystemVerilog associative array whose
  values are queues
- key-level collection behavior
- per-key value-queue behavior delegated to `set_util`
- normalized representation rules for visible keys
- helper APIs for observation, mutation, normalization, and collection-style
  operations
- hex-format debug printing via `sprint` and `print`

Current high-level status:

- `clean()` canonicalizes containers by removing empty-queue keys
- `*_into()` APIs mutate `result` in place and preserve unrelated existing
  content
- keys touched by `merge_into()` replace the existing queue at that key
- keys whose `intersect_into()` / `diff_into()` result is empty are left
  unchanged in `result`
- value-queue behavior continues to delegate to `set_util`
- `sprint` and `print` format each key with `%x` and delegate value-queue
  formatting to `val_set_util::sprint` (also `%x`); the output is one
  `key: {v0, v1, ...}` pair per indented line under the name

## Where To Read The Code

Start here:

- `libs/aa_of_q_util.svh`

Then read these dependencies:

- `libs/set_util.svh`
  value-queue behavior and delegated set semantics
- `libs/aa_util.svh`
  map-style structure and naming conventions that `aa_of_q_util` follows
- `libs/aa_value_adapter_util.svh`
  interoperability layer for projecting between `aa_of_q_t` and `aa_t`

Then read the focused testbench:

- `tests/aa_of_q_util_tb.sv`

## Recommended Reading Order

For someone trying to understand this feature:

1. Read the class-level comment in `libs/aa_of_q_util.svh`.
2. Read the public API declarations in the class body.
3. Read the class-external function bodies and their implementation notes.
4. Read `tests/aa_of_q_util_tb.sv` to see the intended behavior and edge cases.
5. Read `libs/set_util.svh` if you need the delegated value semantics.
6. Read `libs/aa_value_adapter_util.svh` if you need the scalar-map bridge.

## How This File Fits In The Repository

`aa_of_q_util` is part of the collection utility layer under `libs/`.

- `set_util.svh` is the queue/set layer
- `aa_util.svh` is the associative-array/map layer
- `aa_of_q_util.svh` combines those ideas into the multimap layer

If you are extending multimap behavior, this is the main file to change.
If you are changing queue-level semantics, check `set_util.svh` first.

## Notes For Readers

- Use this `docs/` page for orientation, not for authoritative API details.
- Treat the source comments in `libs/aa_of_q_util.svh` as the detailed contract.
- Treat the testbench as the executable view of the intended behavior.

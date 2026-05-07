# `aa_value_adapter_util`

## What It Is

`aa_value_adapter_util` is the repository's adapter between scalar-map values
and queue-valued multimap entries.

It is the code location to read when you want to treat `aa_t` as the scalar
view of an `aa_of_q_t` container.

This document is intentionally high level. Detailed API semantics, contracts,
and boundary conditions live in the source comments of
`libs/aa_value_adapter_util.svh`.

## What Feature It Covers

This feature covers:

- containment between `aa_of_q_t` and `aa_t`
- merge, intersect, and diff operations across the two container shapes
- projection from `aa_of_q_t` to `aa_t`
- lifting from `aa_t` back to `aa_of_q_t`
- value-queue behavior delegated to `set_util`

Current high-level status:

- `to_aa_of_q()` wraps each scalar value as a singleton queue
- `to_aa()` expects singleton queues and extracts the scalar value
- `*_into()` APIs mutate `result` in place and preserve unrelated existing
  content
- keys touched by `merge_into()` replace the existing queue at that key
- keys whose `intersect_into()` / `diff_into()` result is empty are left
  unchanged in `result`
- the collection APIs are adapter-style operations, not new container rules

## Where To Read The Code

Start here:

- `libs/aa_value_adapter_util.svh`

Then read these dependencies:

- `libs/aa_of_q_util.svh`
  normalized multimap behavior that this adapter builds on
- `libs/aa_util.svh`
  scalar map shape that this adapter projects to and from
- `libs/set_util.svh`
  queue/set behavior used when the adapter manipulates per-key values

## Recommended Reading Order

For someone trying to understand this feature:

1. Read the class-level comment in `libs/aa_value_adapter_util.svh`.
2. Read the public API declarations in the class body.
3. Read the focused testbench in `tests/aa_value_adapter_util_tb.sv`.
4. Read `libs/aa_of_q_util.svh` and `libs/aa_util.svh` for the underlying
   container contracts.

## How This File Fits In The Repository

`aa_value_adapter_util` is the interoperability layer between the repository's
queue-valued multimap helper and its scalar map helper.

If you are changing cross-type semantics, this is the main file to change.
If you are changing the underlying multimap or map contracts, check
`aa_of_q_util.svh` and `aa_util.svh` first.

## Notes For Readers

- Use this `docs/` page for orientation, not for authoritative API details.
- Treat the source comments in `libs/aa_value_adapter_util.svh` as the
  detailed contract.
- Treat the testbench as the executable view of the intended behavior.

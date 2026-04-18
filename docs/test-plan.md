# Collection Test Plan

## Scope

This plan covers the current utility-only collection layer:

- `set_util.svh`
- `aa_util.svh`

The goal is to validate both API semantics and the assumptions documented in the source comments.

## Test Levels

1. Smoke

- `collection_smoke_tb.sv`
- Fast regression for the most common paths
- Useful as a sanity check after small edits

2. Focused unit coverage

- `set_util_tb.sv`
- `aa_util_tb.sv`
- Broader API-by-API checking, including edge cases and mutating behavior

## Coverage Matrix

### `set_util`

- `insert`
  - insert new key
  - insert duplicate key
- `delete`
  - delete existing key
  - delete absent key
- `contains_key`
  - present key
  - absent key
- `contains_set`
  - proper subset
  - non-subset
  - empty subset
- `equals`
  - exact key match
  - proper-subset mismatch
  - same-size different-key mismatch
- `to_queue`
  - exported count matches input set
  - all keys preserved
- `to_aa`
  - all keys preserved
  - result is copy semantics, not alias semantics
- `union_into`
  - union keys inserted into pre-populated result
  - existing unrelated result contents preserved
- `get_union`
  - pure union result
- `union_with`
  - in-place mutation of lhs
- `intersect_into`
  - shared keys inserted into pre-populated result
  - existing unrelated result contents preserved
- `get_intersect`
  - pure intersection result
- `intersect_with`
  - lhs shrinks to shared keys only
- `diff_into`
  - lhs-only keys inserted into pre-populated result
  - existing unrelated result contents preserved
- `get_diff`
  - pure difference result
- `diff_with`
  - shared keys removed from lhs
  - empty-set boundary case

### `aa_util`

- `sprint`
  - empty map
  - populated map
- `print`
  - callable without runtime failure
- `equals`
  - identical entries
  - same-size different-key mismatch
  - mismatched values
  - X/Z-sensitive comparison
- `equals_verbose`
  - success path clears diff string
  - mismatch path produces diff text
- `contains`
  - matching sub-map
  - mismatched shared value
- `contains_keys`
  - subset of keys present
- `has_key`
  - present key
  - absent key
- `has_value`
  - present payload
  - absent payload
  - X/Z-sensitive match
- `merge_into`
  - rhs overwrites shared keys
  - result fully overwritten
- `get_merge`
  - pure merge result
- `merge_with`
  - in-place mutation of lhs
- `intersect_into`
  - shared keys only
  - payload preserved from lhs
  - result fully overwritten
- `get_intersect`
  - pure intersection result
- `intersect_with`
  - lhs shrinks to shared keys only
- `get_intersect_merge_with`
  - returned map contains old overwritten values
  - lhs mutated to merged result
- `diff_into`
  - lhs-only keys preserved with lhs payload
  - result fully overwritten
- `get_diff`
  - pure difference result
- `diff_with`
  - shared keys removed from lhs
- `get_keys`
  - all keys exported into set form
- `get_values`
  - duplicate values deduplicated naturally

## Pass Criteria

All testbenches must:

- compile with `slang`
- compile and elaborate with XSim
- terminate with `PASS`
- terminate without `$error` or `$fatal`

## Known Behavioral Contracts

- `set_util::*_into()` preserves unrelated pre-existing content in `result`
- `set_util::equals()` only compares key sets
- `aa_util::*_into()` fully overwrites `result`
- `aa_util::equals()` compares both key sets and values
- `aa_util::intersect_*` and `aa_util::diff_*` preserve payload from lhs
- `aa_util::merge_*` resolves key conflicts in favor of rhs

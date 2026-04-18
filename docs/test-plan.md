# Collection Test Plan

## Scope

This plan covers the current utility-only collection layer:

- `set_util.svh`
- `aa_util.svh`
- `multimap_util.svh`

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

3. Multi-value map coverage

- `multimap_util_tb.sv`
- Focused coverage for `aa of set` semantics, especially per-key set operations

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

### `multimap_util`

Implementation note:

- default path uses an XSim-compatible bucket-handle wrapper around each value-set
- defining `COLLECTION_USE_NESTED_AA_MULTIMAP` switches to the native nested associative-array form
- both paths are intended to preserve identical public semantics

- `insert`
  - insert new `<key, value>` pair
  - duplicate value deduplication under same key
- `add_values`
  - bulk-add value-set to one key
- `num_keys`
  - count distinct keys only
- `num_values`
  - existing key
  - missing key
- `has_key`
  - present key
  - absent key
- `contains_value`
  - present pair
  - absent pair
- `contains`
  - matching sub-multimap
  - missing key/value-set mismatch
- `equals`
  - identical multimap
  - different key set
  - different value-set on shared key
- `merge_into`
  - shared key performs set union
  - result fully overwritten
- `get_merge`
  - pure merge result
- `merge_with`
  - in-place merge
- `intersect_into`
  - per-key value-set intersection
  - empty intersections dropped
  - result fully overwritten
- `get_intersect`
  - pure intersection result
- `intersect_with`
  - in-place intersection
- `diff_into`
  - per-key value-set difference
  - empty remainders dropped
  - result fully overwritten
- `get_diff`
  - pure difference result
- `diff_with`
  - in-place difference
- `get_keys`
  - all keys exported into set form
- `get_values`
  - existing key
  - missing key returns empty set
- `sprint` / `print`
  - empty and populated multimap formatting
- macro variants
  - default XSim-compatible path
  - nested-AA path accepted by `slang`

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
- `multimap_util::*_into()` fully overwrites `result`
- `multimap_util::merge_*` unions value-sets on shared keys
- `multimap_util::intersect_*` and `diff_*` drop keys whose result value-set is empty
- `multimap_util` supports two in-file implementations selected by `COLLECTION_USE_NESTED_AA_MULTIMAP`

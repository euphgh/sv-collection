# Generator Strategy

## Purpose

This page records the code-generation strategy for array-style collection
utilities under `libs/`.

The goal is to generate the repetitive slot-wise forwarding code with Python,
while keeping API contracts and semantic decisions hand-written in source
comments.

## Scope

This strategy applies to array-style helpers such as:

- `set_array_util`
- future array forms of `aa_util`
- future array forms of `aa_of_q_util`
- future array forms of `aa_value_adapter_util`

The discussion below uses `set_array_util` as the concrete reference.

Generated `.svh` files should live under `libs/generated/`.

## High-Level Split

Split each array utility into two parts:

1. Hand-written contract surface.
2. Generated mechanical implementation.

The hand-written part owns the API meaning. The generated part owns the
repetitive slot-wise forwarding.

## Hand-Written Part

Keep these pieces manual:

- class-level purpose comment
- API contracts for each public method
- normalization rules
- `@pre` / `@post` wording
- any feature-specific exceptions
- wrapper functions that must stay inline for toolchain stability
- any special formatting policy that is not a pure loop template
- `sprint` / `print` when their format is feature-specific and should remain
  explicit in source comments

For `set_array_util`, the hand-written surface should define the public API and
its contract, including:

- `equals`
- `contains`
- `union_into`, `get_union`, `union_with`
- `intersect_into`, `get_intersect`, `intersect_with`
- `diff_into`, `get_diff`, `diff_with`
- `sprint`, `print`

## Generated Part

Generate the repetitive pieces that follow a stable pattern:

- per-slot `for` / `foreach` loops
- calls to the delegated element utility
- repeated `typedef` aliases derived from the element utility

For `set_array_util`, the generator should emit the bodies for the
slot-forwarding `void` functions:

- `union_into`
- `union_with`
- `intersect_into`
- `intersect_with`
- `diff_into`
- `diff_with`

The generator should not own `sprint` / `print` if their formatting is part of
the human-facing API contract.

## Wrapper Pattern

Use inline wrappers for functions that return nested typedefs or otherwise need
to avoid out-of-block return instability.

This follows the repository note that VCS W-2024.09-SP1 has been observed to
segfault on some out-of-block methods that return a nested class typedef
directly.

Recommended structure:

- keep the public `get_*` function inline in the class body
- have it allocate a local result variable
- call the generated `*_into` function
- return the local result

For example, `get_union` should stay an inline wrapper around `union_into`.
The generated body belongs in `union_into`, not in `get_union`.

This pattern avoids toolchain risk while preserving the public API.

The same rule applies when the return value is a nested array typedef that is
defined inside the class.
If VCS shows instability for that pattern, keep the wrapper inline or reshape
the return type.

## `set_array_util` Example

### Public API

The public array API should stay small and array-oriented.

It should expose array-level collection semantics, not slot-local wrappers.

### Generation Plan

For `set_array_util`, generate the `.svh` file in `libs/generated/` from a
feature-specific Python script.

Keep the generated file focused on the mechanical slot-forwarding code.
Keep the source of truth for API wording in the hand-written contracts.

### Generated Mechanics

The generator should produce the repeated slot traversal for each array-level
operation.

For `set_array_util`, that means each bank of `lhs` / `rhs` should be forwarded
to the matching element utility call.

### Wrapper Calls

Public return-value functions should call the `void` helpers internally.

Example pattern:

```systemverilog
static function set_array_t get_union(const ref set_array_t lhs,
                                      const ref set_array_t rhs);
    set_array_t result;

    union_into(lhs, rhs, result);
    return result;
endfunction
```

This keeps the return-value function short and toolchain-friendly.

## Suggested File Structure

Use this division inside the `.svh` file:

- class comment and API contracts at the top
- typedefs and public declarations in the class body
- inline wrappers for return-value APIs
- generated bodies for the slot-forwarding `void` APIs
- helper functions only when the feature genuinely needs them

## Open Questions

These points should be confirmed before automating the generator fully:

- `sprint` still needs one unified shape across `set`, `aa`, and `aa_of_q`.
- Future array utilities should start with one feature-specific script each,
  even if a shared generator engine is reused underneath later.

## Notes

This page is about library code only.
Testbench strategy is documented elsewhere.

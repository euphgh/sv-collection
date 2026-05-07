# AGENTS.md

## Scope

This file defines the default documentation and code-organization rules for
future development in this repository, especially for SystemVerilog utility
classes under `libs/`.

Documentation in this repository is layered. Use the layers for different
purposes instead of repeating the same detail everywhere.

- Agent reading order: `AGENTS.md` -> `README` -> `docs/` -> code
- Human reading order: `README` -> `docs/` -> code

Document roles:

- `AGENTS.md`: repository rules, conventions, workflows, and development
  expectations
- `README`: repository-level introduction, purpose, setup, and usage entry
  points
- `docs/`: high-level guidance, feature map, folder purpose, and where to read
  code
- code comments: detailed API contracts, semantics, edge cases, and invariants

If detailed behavior is already documented in code comments, do not duplicate
that detail in `docs/` or `README`. Those documents should guide readers toward
the relevant code rather than restating the full contract.

If you need code-related design notes, API contracts, or framework documents,
look in the `docs/` directory first for orientation, then move to the source
files for authoritative detail.

## Documentation Style

Use `README` and files under `docs/` as reader guidance documents.

- Explain what a feature is, why it exists, and where its code lives.
- Describe the role of folders and major files at a high level.
- Point readers to the source files and tests they should read next.
- Do not restate full API details, per-argument behavior, or edge-case rules
  that are already captured in source comments.
- Keep detailed contracts in code so the code remains the primary reference.

## Comment Style

Use Doxygen-style documentation comments for public APIs and important helper
APIs.

- Always use `/** ... */` doc blocks.
- Start each class and function doc block with `@brief`.
- Do not use HTML paragraph tags such as `<p>` for separation.
- After `@brief`, add an optional detail section only when it adds contract
  information, design intent, boundary conditions, or usage constraints.
- Use Doxygen tags consistently when applicable:
  - `@tparam` for type parameters
  - `@param` for function parameters
  - `@return` for non-`void` return values
  - `@pre` for caller obligations and required input invariants
  - `@post` for guaranteed output invariants or mutation results
- Prefer documenting behavioral contracts over implementation details.
- State normalization requirements, visibility rules, and semantic delegation
  explicitly in the API docs when they are part of the contract.

## SystemVerilog Utility Class Layout

For reusable utility classes in `*.svh` files, prefer an interface-first file
layout so users can read the API surface without scanning implementation code.

- Put type definitions and function declarations inside the class.
- Prefer `extern static function` declarations in the class body.
- Implement functions outside the class body using
  `class_name#(... )::function_name(...)` style definitions.
- Group the class body by API intent when helpful, for example:
  - public API
  - private helpers
- If a helper is part of the user-facing workflow, keep it public and document
  why it exists.
- If a helper is internal-only, keep it separated from the public API section
  and document it as an internal helper.

## Framework-First Development

When APIs are still being designed, do not rush into full implementations.

- It is acceptable to create empty function bodies first.
- In empty bodies, add concise implementation notes describing:
  - the required cases to handle
  - delegated utilities or dependencies
  - normalization or mutation constraints
  - open semantic questions that must be resolved before implementation
- Do not silently invent uncertain semantics. Raise them for confirmation.

## Syntax Verification

After changing SystemVerilog source files, run at least one syntax-oriented lint
or compile check before considering the work complete.

- Prefer using the repository's existing filelists or package entry points.
- Use `slang` or `vcs` with project-compatible options.
- If full-project lint is blocked by unrelated pre-existing errors, run a
  narrower check that still covers the files you changed.
- For library changes in this repository, `slang -I libs --std 1800-2017
  --compat vcs libs/collection_pkg.sv` is a valid targeted syntax check.

## Testbench Isolation

When writing focused testbenches for a specific utility under `libs/`, prefer
isolated compilation that includes only the file under test and its direct
includes.

- For a focused `aa_of_q_util` testbench, use `` `include "aa_of_q_util.svh" ``
  directly in the testbench instead of importing `collection_pkg`.
- Avoid package imports in file-focused tests when the goal is to prevent
  unrelated library code from affecting the test.
- Prefer a narrow syntax check such as
  `slang -I libs --std 1800-2017 --compat vcs tests/aa_of_q_util_tb.sv` for
  this style of isolated testbench.

## aa_of_q-style Container Rules

The following rules apply to multimap-style containers such as `aa_of_q_util`
and should be reused by similar container utilities unless explicitly changed.

- The container model is `KEY_T -> VAL_T[$]`.
- Key-level behavior is map-like.
- Value-queue behavior is delegated to `set_util#(VAL_T, UNIQUE_ELEM)`.
- Semantics that depend on uniqueness or duplicate handling must follow the
  corresponding `set_util` contract rather than redefining them locally.

### Normalized Representation

A normalized associative-array-of-queue container must satisfy this invariant:

- every visible key maps to a non-empty queue

Rules derived from this invariant:

- Public APIs may require inputs to already be normalized.
- APIs returning an `aa_of_q_t` should return normalized results.
- Keys backed by empty queues are not considered visible.
- Provide a public normalization API, for example `clean(...)`, when callers
  may need to canonicalize data created outside the utility class.
- Document normalization requirements with `@pre` and `@post` tags.

## Collection API Semantics

For collection-style APIs such as `merge`, `intersect`, and `diff`:

- Write the exact semantic contract in the doc block.
- If key-level and value-level behaviors are different, document both.
- If empty intermediate results must remove keys from the observable result,
  state that explicitly.
- If behavior depends on another utility such as `set_util`, say so directly in
  the docs instead of restating a second contract.

## Writing Style

- Prefer short, declarative sentences.
- Keep naming and terminology stable across files.
- Use `normalized`, `visible key`, `delegates to`, and similar contract terms
  consistently once introduced.
- Avoid vague wording such as "handle various cases" when a more precise rule
  can be written.

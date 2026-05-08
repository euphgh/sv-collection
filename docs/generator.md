# Generator Strategy

## Purpose

This page gives the high-level generation story for array-style utility
helpers under `libs/`.

The generator reads a hand-written `.svh` source file, finds the functions that
are marked for generation, and writes the repetitive implementation bodies into
an output `.svh` file.

The source file remains the contract source of truth. The generator only owns
mechanical repetition.

## Scope

This strategy applies to array-style helpers such as:

- `set_array_util`
- future array forms of `aa_util`
- future array forms of `aa_of_q_util`
- future array forms of `aa_value_adapter_util`

Use this page as orientation, then read the source comments in the feature file
for the actual contract.

## Feature Shape

The shared pattern is:

1. The feature file defines the class, typedefs, and hand-written contracts.
2. Marked `extern` functions are identified for generation.
3. The Python script emits the corresponding implementation bodies.
4. The source file includes the generated output during compilation.

The exact marker syntax, script usage, and validation rules live in the Python
script header comments.

The script-side parser is intended to stay reusable across `set_array_util` and
future `aa_*` array generators.

## Generated Output Location

The output file is typically placed under `libs/generated/`.

For feature files that use a generated include, the include target should be
declared in the source file with a dedicated `// @gen:output` line directly
above the `include` statement.

Read the feature source file and the generator script together to see the exact
layout.

The output include line is part of the feature source contract, not this page.

## What To Read Next

Start here:

- `libs/set_array_util.svh`
- `scripts/generate_set_array_util.py`

Then read the generated output file in `libs/generated/` to see the split
between contract and implementation.

## Notes

This page intentionally stays high level.

Detailed marker syntax, examples, and CLI usage belong in the generator script
comments rather than here.

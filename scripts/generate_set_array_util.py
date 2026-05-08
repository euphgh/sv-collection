#!/usr/bin/env python3
"""@brief Generates the `set_array_util` implementation file.

Usage:
```bash
python scripts/generate_set_array_util.py <path/to/set_array_util.svh>
```

This script reuses the shared collection codegen parser and applies the
`set_array_util` feature-specific rendering rules.

Supported generation rules:
- `// @gen` opts a function into generation.
- `// gen:reduce=and|or|xor` is required for generated non-`void` functions.
- `// @gen:output` must appear immediately above the include line that names
  the generated output file.
- Unsupported signatures fail fast.

Reduce rendering:
- `and` -> native SystemVerilog array `and()` reduction
- `or` -> native SystemVerilog array `or()` reduction
- `xor` -> native SystemVerilog array `xor()` reduction

The script must stop on invalid input and must not silently skip violations.
"""

from __future__ import annotations

from pathlib import Path
import sys

from collection_codegen import ParsedSource, MarkedFunction, parse_source, render_output_file_header


ROOT = Path(__file__).resolve().parents[1]


def render_void_function(func: MarkedFunction) -> str:
    """@brief Renders a generated void-return function body."""
    if func.name in {"union_into", "intersect_into", "diff_into"}:
        return f"""function void set_array_util::{func.name}(\n    const ref set_array_t lhs,\n    const ref set_array_t rhs,\n    ref set_array_t result\n);\n    for (int i = 0; i < SIZE; i++)\n        set_elem_util_t::{func.name}(lhs[i], rhs[i], result[i]);\nendfunction : {func.name}\n"""

    if func.name in {"union_with", "intersect_with", "diff_with"}:
        return f"""function void set_array_util::{func.name}(\n    ref set_array_t lhs,\n    const ref set_array_t rhs\n);\n    for (int i = 0; i < SIZE; i++)\n        set_elem_util_t::{func.name}(lhs[i], rhs[i]);\nendfunction : {func.name}\n"""

    raise ValueError(f"unsupported void generated function: {func.name}")


def render_scalar_function(func: MarkedFunction) -> str:
    """@brief Renders a generated scalar-return function body."""
    if func.name not in {"equals", "contains"}:
        raise ValueError(f"unsupported scalar generated function: {func.name}")

    if func.reduce_op is None:
        raise ValueError(f"missing reduction operator for {func.name}")

    if func.return_type != "bit":
        raise ValueError(f"unsupported scalar return type for {func.name}: {func.return_type}")

    reduce_method = func.reduce_op
    return f"""function bit set_array_util::{func.name}(\n    const ref set_array_t lhs,\n    const ref set_array_t rhs\n);\n    bit partials[SIZE];\n\n    foreach (lhs[i]) begin\n        partials[i] = set_elem_util_t::{func.name}(lhs[i], rhs[i]);\n    end\n\n    return partials.{reduce_method}();\nendfunction : {func.name}\n"""


def render_generated_source(parsed: ParsedSource) -> str:
    """@brief Renders the generated SystemVerilog implementation file."""
    pieces = [render_output_file_header(parsed.source_path.name), ""]

    for func in parsed.functions:
        if func.return_type == "void":
            pieces.append(render_void_function(func).rstrip())
        else:
            pieces.append(render_scalar_function(func).rstrip())
        pieces.append("")

    return "\n".join(pieces).rstrip() + "\n"


def main() -> None:
    """@brief Writes the generated SystemVerilog file to disk."""
    if len(sys.argv) != 2:
        raise SystemExit("usage: python scripts/generate_set_array_util.py <path/to/set_array_util.svh>")

    source_path = Path(sys.argv[1]).resolve()
    parsed = parse_source(source_path)
    output_path = (source_path.parent / parsed.output_target).resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(render_generated_source(parsed), encoding="utf-8")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        raise SystemExit(str(exc)) from exc

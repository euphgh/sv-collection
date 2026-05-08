#!/usr/bin/env python3
"""@brief Generates the `set_array_util` implementation file.

Usage:
```bash
python scripts/generate_set_array_util.py <path/to/set_array_util.svh>
```

This script reuses the shared collection codegen parser and applies the
`set_array_util` feature-specific rendering rules.

Feature contract:
- `// @gen` opts a function into generation.
- `// gen:reduce=and|or|xor` is required for generated non-`void` functions.
- `// @gen:output` must appear immediately above the include line that names
  the generated output file.
- Each input `.svh` file must define exactly one `class` declaration.
- The generator derives the output class name from that declaration.
- Unsupported signatures fail fast.

Forwarding contract:
- native scalar parameters are forwarded unchanged
- custom parameters are treated as array-shaped parameters
- array-shaped parameters are forwarded element-wise
- the outer function and the forwarded element function keep the same name and
  return semantics
- the only difference between the two signatures is the element shape of array
  parameters

Reduce rendering:
- `and` -> native SystemVerilog array `and()` reduction
- `or` -> native SystemVerilog array `or()` reduction
- `xor` -> native SystemVerilog array `xor()` reduction

The script must stop on invalid input and must not silently skip violations.
"""

from __future__ import annotations

from pathlib import Path
import sys

from collection_codegen import (
    MarkedFunction,
    ParsedSource,
    TypeKind,
    parse_source,
    render_output_file_header,
)


ROOT = Path(__file__).resolve().parents[1]


class ArrayFeatureRenderer:
    """@brief Renders array-style feature bodies from a parsed source file.

    The renderer is feature-neutral except for the configuration supplied by the
    feature script:
    - array type alias names
    - element utility alias name
    - supported generated function names
    - how to render scalar reductions
    """

    def __init__(self, elem_util_name: str):
        self.elem_util_name = elem_util_name

    def render_void_function(self, class_name: str, func: MarkedFunction) -> str:
        """@brief Renders a generated void-return function body."""
        decl_params = func.render_signature_params()
        call_args = func.render_call_args("i", forward_custom=True)

        return f"""function void {class_name}::{func.name}({decl_params});
    for (int i = 0; i < SIZE; i++)
        {self.elem_util_name}::{func.name}({call_args});
endfunction : {func.name}
"""

    def render_scalar_function(self, class_name: str, func: MarkedFunction) -> str:
        """@brief Renders a generated scalar-return function body."""
        if func.reduce_op is None:
            raise ValueError(f"missing reduction operator for {func.name}")

        if func.return_type.kind != TypeKind.NATIVE or func.return_type.text != "bit":
            raise ValueError(
                f"unsupported scalar return type for {func.name}: {func.return_type.text}"
            )

        decl_params = func.render_signature_params()
        call_args = func.render_call_args("i", forward_custom=True)
        reduce_method = func.reduce_op

        return f"""function {func.return_type.render()} {class_name}::{func.name}({decl_params});
    bit partials[SIZE];

    foreach (partials[i]) begin
        partials[i] = {self.elem_util_name}::{func.name}({call_args});
    end

    return partials.{reduce_method}();
endfunction : {func.name}
"""

    def render_generated_source(self, parsed: ParsedSource) -> str:
        """@brief Renders the generated SystemVerilog implementation file."""
        pieces = [render_output_file_header(parsed.source_path.name), ""]

        for func in parsed.functions:
            if func.return_type.kind == TypeKind.VOID:
                pieces.append(
                    self.render_void_function(parsed.class_name, func).rstrip()
                )
            else:
                pieces.append(
                    self.render_scalar_function(parsed.class_name, func).rstrip()
                )
            pieces.append("")

        return "\n".join(pieces).rstrip() + "\n"


def render_generated_source(parsed: ParsedSource) -> str:
    """@brief Renders the generated SystemVerilog implementation file.

    The feature script is responsible for applying the `set_array_util` naming and
    signature rules on top of the shared parse result.
    """
    pieces = [render_output_file_header(parsed.source_path.name), ""]

    for func in parsed.functions:
        if func.return_type.kind == TypeKind.VOID:
            pieces.append(render_void_function(func).rstrip())
        else:
            pieces.append(render_scalar_function(func).rstrip())
        pieces.append("")

    return "\n".join(pieces).rstrip() + "\n"


def main() -> None:
    """@brief Writes the generated SystemVerilog file to disk.

    The command line accepts one feature source file and writes the generated file
    to the output target declared in that source.
    """
    if len(sys.argv) != 2:
        raise SystemExit("usage: python scripts/generate_set_array_util.py <path/to/set_array_util.svh>")

    source_path = Path(sys.argv[1]).resolve()
    parsed = parse_source(source_path)
    output_path = (source_path.parent / parsed.output_target).resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    renderer = ArrayFeatureRenderer(elem_util_name="elem_util")
    output_path.write_text(renderer.render_generated_source(parsed), encoding="utf-8")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        raise SystemExit(str(exc)) from exc

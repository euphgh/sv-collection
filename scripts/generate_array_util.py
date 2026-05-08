#!/usr/bin/env python3
"""@brief Generates array-style collection implementation files.

This script reads a hand-written `.svh` source file, parses the
generated-function markers, and writes the corresponding implementation file to
the include target declared in the source.

Feature files remain the contract source of truth. The generator only owns the
mechanical implementation bodies.
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


class ArrayFeatureRenderer:
    """@brief Renders array-style feature bodies from a parsed source file."""

    def __init__(self, elem_util_name: str):
        self.elem_util_name = elem_util_name

    def render_void_function(
        self, class_name: str, array_dim_name: str, func: MarkedFunction
    ) -> str:
        decl_params = func.render_signature_params()
        call_args = func.render_call_args("i", forward_custom=True)

        return f"""function void {class_name}::{func.name}({decl_params});
    for (int i = 0; i < {array_dim_name}; i++)
        {self.elem_util_name}::{func.name}({call_args});
endfunction : {func.name}
"""

    def render_scalar_function(
        self, class_name: str, array_dim_name: str, func: MarkedFunction
    ) -> str:
        if func.reduce_op is None:
            raise ValueError(f"missing reduction operator for {func.name}")

        if func.return_type.kind != TypeKind.NATIVE or func.return_type.text != "bit":
            raise ValueError(
                f"unsupported scalar return type for {func.name}: {func.return_type.text}"
            )

        decl_params = func.render_signature_params()
        call_args = func.render_call_args("i", forward_custom=True)

        return f"""function {func.return_type.render()} {class_name}::{func.name}({decl_params});
    bit partials[{array_dim_name}];

    foreach (partials[i]) begin
        partials[i] = {self.elem_util_name}::{func.name}({call_args});
    end

    return partials.{func.reduce_op}();
endfunction : {func.name}
"""

    def render_generated_source(self, parsed: ParsedSource) -> str:
        pieces = [render_output_file_header(parsed.source_path.name), ""]

        for func in parsed.functions:
            if func.return_type.kind == TypeKind.VOID:
                pieces.append(
                    self.render_void_function(parsed.class_name, parsed.array_dim_name, func).rstrip()
                )
            else:
                pieces.append(
                    self.render_scalar_function(parsed.class_name, parsed.array_dim_name, func).rstrip()
                )
            pieces.append("")

        return "\n".join(pieces).rstrip() + "\n"


def main() -> None:
    """@brief Writes the generated SystemVerilog file to disk.

    The command line accepts one feature source file and writes the generated
    file to the output target declared in that source.
    """
    if len(sys.argv) != 2:
        raise SystemExit("usage: python scripts/generate_array_util.py <path/to/feature.svh>")

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

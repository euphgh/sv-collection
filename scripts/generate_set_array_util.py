#!/usr/bin/env python3
"""@brief Generates the `set_array_util` implementation file.

This script emits the mechanical `.svh` implementation under
`libs/generated/`.

The hand-written contract remains in `libs/set_array_util.svh`.
"""

from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GENERATED_DIR = ROOT / "libs" / "generated"
GENERATED_FILE = GENERATED_DIR / "set_array_util.svh"


def render_set_array_util() -> str:
    """@brief Renders the generated `set_array_util` source file.

    @return The complete SystemVerilog source text for the generated file.
    """
    return """// This file is generated. The class and contracts live in
// `libs/set_array_util.svh`.

function bit set_array_util::equals(
    const ref set_array_t lhs,
    const ref set_array_t rhs
);
    for (int i = 0; i < SIZE; i++) begin
        if (!set_elem_util_t::equals(lhs[i], rhs[i]))
            return 0;
    end

    return 1;
endfunction : equals

function bit set_array_util::contains(
    const ref set_array_t lhs,
    const ref set_array_t rhs
);
    foreach (rhs[i]) begin
        if (!set_elem_util_t::contains(lhs[i], rhs[i]))
            return 0;
    end

    return 1;
endfunction : contains

function void set_array_util::union_into(
    const ref set_array_t lhs,
    const ref set_array_t rhs,
    ref set_array_t result
);
    for (int i = 0; i < SIZE; i++)
        set_elem_util_t::union_into(lhs[i], rhs[i], result[i]);
endfunction : union_into

function void set_array_util::union_with(
    ref set_array_t lhs,
    const ref set_array_t rhs
);
    for (int i = 0; i < SIZE; i++)
        set_elem_util_t::union_with(lhs[i], rhs[i]);
endfunction : union_with

function void set_array_util::intersect_into(
    const ref set_array_t lhs,
    const ref set_array_t rhs,
    ref set_array_t result
);
    for (int i = 0; i < SIZE; i++)
        set_elem_util_t::intersect_into(lhs[i], rhs[i], result[i]);
endfunction : intersect_into

function void set_array_util::intersect_with(
    ref set_array_t lhs,
    const ref set_array_t rhs
);
    for (int i = 0; i < SIZE; i++)
        set_elem_util_t::intersect_with(lhs[i], rhs[i]);
endfunction : intersect_with

function void set_array_util::diff_into(
    const ref set_array_t lhs,
    const ref set_array_t rhs,
    ref set_array_t result
);
    for (int i = 0; i < SIZE; i++)
        set_elem_util_t::diff_into(lhs[i], rhs[i], result[i]);
endfunction : diff_into

function void set_array_util::diff_with(
    ref set_array_t lhs,
    const ref set_array_t rhs
);
    for (int i = 0; i < SIZE; i++)
        set_elem_util_t::diff_with(lhs[i], rhs[i]);
endfunction : diff_with
"""


def main() -> None:
    """@brief Writes the generated SystemVerilog file to disk."""
    GENERATED_DIR.mkdir(parents=True, exist_ok=True)
    GENERATED_FILE.write_text(render_set_array_util(), encoding="utf-8")


if __name__ == "__main__":
    main()

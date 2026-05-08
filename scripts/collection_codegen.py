#!/usr/bin/env python3
"""@brief Shared parsing helpers for collection code generators.

This module provides the reusable source-file parsing and output-target
discovery logic for feature-specific `.svh` generators under `scripts/`.

Feature scripts should import these helpers, then provide their own body
renderers and feature-specific validation rules.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import re


@dataclass(frozen=True)
class MarkedFunction:
    """@brief Describes one function selected from the source file."""

    return_type: str
    name: str
    params: str
    reduce_op: str | None


@dataclass(frozen=True)
class ParsedSource:
    """@brief Captures the parsed source file and generation target."""

    source_path: Path
    output_target: str
    functions: list[MarkedFunction]


INCLUDE_RE = re.compile(r'^`include\s+"([^"]+)"\s*$')
DECL_RE = re.compile(
    r'^extern\s+static\s+function\s+(.+?)\s+([A-Za-z_][A-Za-z0-9_]*)\s*\((.*)\)\s*;$'
)
REDUCE_RE = re.compile(r'^//\s*gen:reduce=(and|or|xor)\s*$')


def read_lines(path: Path) -> list[str]:
    """@brief Reads a UTF-8 text file and returns split lines."""
    return path.read_text(encoding="utf-8").splitlines()


def find_output_target(lines: list[str]) -> str:
    """@brief Finds the single generated output target declared in the source."""
    target: str | None = None

    for idx, line in enumerate(lines):
        if line.strip() != "// @gen:output":
            continue

        if idx + 1 >= len(lines):
            raise ValueError("missing include after // @gen:output")

        match = INCLUDE_RE.match(lines[idx + 1].strip())
        if match is None:
            raise ValueError("// @gen:output must be followed by an include")

        if target is not None:
            raise ValueError("multiple // @gen:output directives found")

        target = match.group(1)

    if target is None:
        raise ValueError("no // @gen:output directive found")

    return target


def _collect_declaration(lines: list[str], start_idx: int) -> tuple[str, int]:
    """@brief Collects a multiline function declaration."""
    decl_parts: list[str] = []
    idx = start_idx

    while idx < len(lines):
        decl_parts.append(lines[idx].strip())
        if ";" in lines[idx]:
            break
        idx += 1

    return " ".join(part for part in decl_parts if part), idx


def collect_marked_functions(lines: list[str]) -> list[MarkedFunction]:
    """@brief Collects all `@gen`-marked extern functions from source text."""
    functions: list[MarkedFunction] = []
    idx = 0

    while idx < len(lines):
        if lines[idx].strip() != "// @gen":
            idx += 1
            continue

        reduce_op: str | None = None
        decl_idx = idx + 1

        while decl_idx < len(lines):
            stripped = lines[decl_idx].strip()
            if not stripped:
                decl_idx += 1
                continue

            reduce_match = REDUCE_RE.match(stripped)
            if reduce_match is not None:
                if reduce_op is not None:
                    raise ValueError("duplicate gen:reduce directive")
                reduce_op = reduce_match.group(1)
                decl_idx += 1
                continue

            if stripped.startswith("//"):
                raise ValueError("unexpected comment between @gen and declaration")

            break

        if decl_idx >= len(lines):
            raise ValueError("unterminated generated function declaration")

        decl_text, end_idx = _collect_declaration(lines, decl_idx)
        match = DECL_RE.match(decl_text)
        if match is None:
            raise ValueError(f"unable to parse generated declaration: {decl_text}")

        return_type = match.group(1).strip()
        name = match.group(2)
        params = match.group(3).strip()

        if return_type == "void":
            if reduce_op is not None:
                raise ValueError(f"void function {name} must not declare gen:reduce")
        else:
            if reduce_op is None:
                raise ValueError(f"non-void function {name} requires gen:reduce")

        functions.append(
            MarkedFunction(
                return_type=return_type,
                name=name,
                params=params,
                reduce_op=reduce_op,
            )
        )
        idx = end_idx + 1

    return functions


def parse_source(path: Path) -> ParsedSource:
    """@brief Parses a source file and returns its generation metadata."""
    lines = read_lines(path)
    return ParsedSource(
        source_path=path,
        output_target=find_output_target(lines),
        functions=collect_marked_functions(lines),
    )


def render_output_file_header(source_name: str) -> str:
    """@brief Renders the standard generated-file header comment."""
    return (
        "// This file is generated. The class and contracts live in\n"
        f"// `libs/{source_name}`.\n"
    )

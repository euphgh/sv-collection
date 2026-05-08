#!/usr/bin/env python3
"""@brief Shared parsing helpers for collection code generators.

This module provides the reusable source-file parsing and output-target
discovery logic for feature-specific `.svh` generators under `scripts/`.

The parser models marked functions in a feature-neutral way:
- return types are structured into native, custom, and void forms
- parameters preserve direction, qualifiers, type, and name
- feature scripts are responsible for mapping array-shaped parameters to their
  element-shaped forwarding form

Feature scripts should import these helpers, then provide their own body
renderers and feature-specific validation rules.
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from pathlib import Path
import re


class TypeKind(Enum):
    """@brief Describes the parsed type family for a function signature."""

    VOID = "void"
    NATIVE = "native"
    CUSTOM = "custom"


@dataclass(frozen=True)
class TypeSpec:
    """@brief Describes one parsed SystemVerilog type."""

    kind: TypeKind
    text: str

    def render(self) -> str:
        """@brief Returns the original textual type representation."""
        return self.text

    def as_forward_type(self) -> "TypeSpec":
        """@brief Returns the element-shaped type used by forwarded calls.

        Custom array-shaped types are normalized by dropping the `_array`
        segment when present, for example `set_array_t` becomes `set_t`.
        Native scalar types are returned unchanged.
        """
        if self.kind != TypeKind.CUSTOM:
            return self

        match = re.match(r"^(.*)_array_t$", self.text)
        if match is None:
            return self

        return TypeSpec(kind=TypeKind.CUSTOM, text=f"{match.group(1)}_t")


@dataclass(frozen=True)
class ParamSpec:
    """@brief Describes one parsed function parameter.

    The parser preserves the raw source text needed by feature scripts, while
    still exposing the key pieces for signature and call rendering.
    """

    direction: str
    attrs: tuple[str, ...]
    type_spec: TypeSpec
    name: str

    def render_signature(self, type_spec: TypeSpec | None = None) -> str:
        """@brief Renders the parameter as a function declaration item."""
        resolved_type = type_spec or self.type_spec
        parts = list(self.attrs)
        parts.append(self.direction)
        parts.append(resolved_type.render())
        parts.append(self.name)
        return " ".join(part for part in parts if part)

    def render_call(self, index_expr: str | None = None) -> str:
        """@brief Renders the parameter as a forwarded call argument."""
        if index_expr is None:
            return self.name
        return f"{self.name}[{index_expr}]"


@dataclass(frozen=True)
class MarkedFunction:
    """@brief Describes one function selected from the source file.

    This object is intentionally feature-neutral.
    Feature scripts should use it to render both the outer function signature
    and the element-forwarding call signature.

    The model stores a typed return specification and a typed parameter list so
    feature scripts can evolve the rendering rules without changing the parser
    API.
    """

    return_type: TypeSpec
    name: str
    params: tuple[ParamSpec, ...]
    reduce_op: str | None

    def render_signature_params(self, forward: bool = False) -> str:
        """@brief Renders the parameter list for a function declaration.

        When `forward` is true, custom array-shaped parameters are rendered as
        their element-shaped types for the element-level call signature.
        """
        return ", ".join(
            param.render_signature(
                param.type_spec.as_forward_type() if forward else param.type_spec
            )
            for param in self.params
        )

    def render_call_args(self, index_expr: str | None = None, forward_custom: bool = True) -> str:
        """@brief Renders the parameter list for a forwarded function call.

        When `forward_custom` is true, custom array-shaped parameters are indexed
        using `index_expr` and native scalar parameters are forwarded unchanged.
        """
        args: list[str] = []
        for param in self.params:
            if forward_custom and param.type_spec.kind == TypeKind.CUSTOM:
                args.append(param.render_call(index_expr))
            else:
                args.append(param.render_call(None))
        return ", ".join(args)


@dataclass(frozen=True)
class ParsedSource:
    """@brief Captures the parsed source file and generation target."""

    source_path: Path
    class_name: str
    output_target: str
    functions: list[MarkedFunction]


INCLUDE_RE = re.compile(r'^`include\s+"([^"]+)"\s*$')
DECL_RE = re.compile(
    r'^extern\s+static\s+function\s+(.+?)\s+([A-Za-z_][A-Za-z0-9_]*)\s*\((.*)\)\s*;$'
)
CLASS_RE = re.compile(r'^class\s+([A-Za-z_][A-Za-z0-9_]*)\b')
REDUCE_RE = re.compile(r'^//\s*gen:reduce=(and|or|xor)\s*$')
NATIVE_TYPES = {
    "bit",
    "byte",
    "shortint",
    "int",
    "longint",
    "integer",
    "time",
    "real",
    "shortreal",
    "realtime",
    "logic",
    "reg",
    "string",
}


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


def find_class_name(lines: list[str]) -> str:
    """@brief Finds the single class declaration in the source file.

    The generator contract requires exactly one `class` declaration per input
    file.
    """
    class_name: str | None = None

    for line in lines:
        match = CLASS_RE.match(line.strip())
        if match is None:
            continue

        if class_name is not None:
            raise ValueError("multiple class declarations found")

        class_name = match.group(1)

    if class_name is None:
        raise ValueError("no class declaration found")

    return class_name


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


def _parse_type(text: str) -> TypeSpec:
    """@brief Parses a raw SystemVerilog type string."""
    normalized = text.strip()
    kind = (
        TypeKind.VOID
        if normalized == "void"
        else TypeKind.NATIVE
        if normalized in NATIVE_TYPES
        else TypeKind.CUSTOM
    )
    return TypeSpec(kind=kind, text=normalized)


def _split_params(params_text: str) -> list[str]:
    """@brief Splits a parameter list on top-level commas."""
    if not params_text.strip():
        return []

    params: list[str] = []
    depth = 0
    start = 0
    for idx, ch in enumerate(params_text):
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        elif ch == "," and depth == 0:
            params.append(params_text[start:idx].strip())
            start = idx + 1
    params.append(params_text[start:].strip())
    return [item for item in params if item]


def _parse_param(param_text: str) -> ParamSpec:
    """@brief Parses one function parameter."""
    parts = param_text.split()
    if len(parts) < 2:
        raise ValueError(f"unable to parse parameter: {param_text}")

    direction_idx = None
    for idx, token in enumerate(parts):
        if token in {"input", "output", "inout", "ref"}:
            direction_idx = idx
            break

    if direction_idx is None:
        raise ValueError(f"unsupported parameter direction: {param_text}")

    direction = parts[direction_idx]
    name = parts[-1]
    attrs = tuple(parts[:direction_idx])
    type_text = " ".join(parts[direction_idx + 1 : -1]).strip()
    if not type_text:
        raise ValueError(f"unable to parse parameter type: {param_text}")

    return ParamSpec(
        direction=direction, attrs=attrs, type_spec=_parse_type(type_text), name=name
    )


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

        return_type = _parse_type(match.group(1).strip())
        name = match.group(2)
        params_text = match.group(3).strip()
        params = tuple(_parse_param(item) for item in _split_params(params_text))

        if return_type.kind == TypeKind.VOID:
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
        class_name=find_class_name(lines),
        output_target=find_output_target(lines),
        functions=collect_marked_functions(lines),
    )


def render_output_file_header(source_name: str) -> str:
    """@brief Renders the standard generated-file header comment."""
    return (
        "// This file is generated. The class and contracts live in\n"
        f"// `libs/{source_name}`.\n"
    )

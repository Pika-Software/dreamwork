#!/usr/bin/env python3
"""
Builds a GitBook-style static site from the LuaLS meta definitions.

Parses the EmmyLua annotations of a meta `library/` tree (the generated `meta`
branch) and emits HTML pages for libraries, classes and data types with their
functions, methods, fields and events, plus a client-side search index.

Classes are tables that construct objects: a companion `*Class` with
`---@overload fun(...): T` / `---@operator call: T`, the instance type usually
inherits `: Object`.

The site works from `file://` too, nothing is fetched at runtime.

Usage: generate_docs.py --input <meta root> --output <docs dir>
       [--repo-url <url>] [--source-ref <branch>] [--base-path </repo>] [--strict] [--verbose]
"""

from __future__ import annotations

import argparse
import html
import json
import re
import shutil
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable

sys.path.insert(0, str(Path(__file__).resolve().parent))

from generate_meta import split_type  # noqa: E402


# ---------------------------------------------------------------------------
# Models
# ---------------------------------------------------------------------------


@dataclass
class Param:
    name: str
    type: str = ""
    description: str = ""
    optional: bool = False


@dataclass
class Return:
    type: str = ""
    name: str = ""
    description: str = ""


@dataclass
class Field:
    name: str
    type: str = ""
    description: str = ""
    visibility: str = "public"  # public | protected | private | package
    optional: bool = False
    realm: str = ""
    value: str = ""  # literal value or the aliased path
    alias_of: str = ""
    source: str = ""
    line: int = 0


@dataclass
class Function:
    name: str
    full_name: str
    kind: str  # function | method | static
    receiver: str = ""
    params: list[Param] = field(default_factory=list)
    returns: list[Return] = field(default_factory=list)
    description: str = ""
    realm: str = ""
    overloads: list[str] = field(default_factory=list)
    see: list[str] = field(default_factory=list)
    visibility: str = "public"
    nodiscard: bool = False
    async_: bool = False
    deprecated: str | None = None
    alias_of: str = ""
    source: str = ""
    line: int = 0


@dataclass
class ClassInfo:
    name: str
    parents: list[str] = field(default_factory=list)
    description: str = ""
    realm: str = ""
    fields: list[Field] = field(default_factory=list)
    methods: list[Function] = field(default_factory=list)
    statics: list[Function] = field(default_factory=list)
    overloads: list[str] = field(default_factory=list)
    operators: list[str] = field(default_factory=list)
    see: list[str] = field(default_factory=list)
    deprecated: str | None = None
    source: str = ""
    line: int = 0
    declared: bool = False  # has a `---@class` annotation
    is_class: bool = False  # constructible Object class
    is_library: bool = False
    is_type: bool = False  # data structure / interface without a constructor
    instance_of: str = ""  # if this is a *Class companion, the instance type
    class_of: str = ""  # companion Class type name
    constructor: str = ""  # constructor global name


@dataclass
class AliasInfo:
    name: str
    definition: str = ""
    description: str = ""
    variants: list[tuple[str, str]] = field(default_factory=list)
    source: str = ""
    line: int = 0


@dataclass
class LibraryInfo:
    name: str
    description: str = ""
    realm: str = ""
    functions: list[Function] = field(default_factory=list)
    fields: list[Field] = field(default_factory=list)
    nested_classes: list[str] = field(default_factory=list)
    see: list[str] = field(default_factory=list)
    source: str = ""
    line: int = 0


@dataclass
class DocBlock:
    description: str = ""
    realm: str = ""
    tags: list[tuple[str, str]] = field(default_factory=list)
    variants: list[tuple[str, str]] = field(default_factory=list)  # `---| value # comment`
    start_line: int = 0


@dataclass
class ValueDef:
    """`owner.key = <rhs>` with an optional doc block, attached after every file is parsed."""

    owner: str
    key: str
    rhs: str
    block: DocBlock | None
    source: str
    line: int


# ---------------------------------------------------------------------------
# Type expressions
# ---------------------------------------------------------------------------

GENERIC_STRIP = re.compile(r"<[^>]*>")


def strip_generic(name: str) -> str:
    return GENERIC_STRIP.sub("", name).strip()


def base_name(name: str) -> str:
    return strip_generic(name).split(".")[-1]


def escape(text: str) -> str:
    return html.escape(text, quote=True)


def normalize_ws(text: str) -> str:
    return re.sub(r"[ \t]+\n", "\n", text).strip()


def split_type_list(text: str) -> tuple[list[str], str]:
    """Splits `T1, T2, T3 rest` (multiple returns on one `@return` line)."""
    types: list[str] = []
    rest = text.strip()
    while rest:
        typ, rest = split_type(rest)
        if not typ:
            break

        types.append(typ)
        if not rest.startswith(","):
            break

        rest = rest[1:].strip()

    return types, rest


def find_closing(text: str, start: int) -> int:
    """Index of the bracket closing the one at `start`, or -1."""
    pairs = {"(": ")", "<": ">", "[": "]", "{": "}"}
    stack: list[str] = []
    i = start
    while i < len(text):
        c = text[i]
        if c in "\"'`":
            end = text.find(c, i + 1)
            if end < 0:
                return -1

            i = end
        elif c in pairs:
            stack.append(pairs[c])
        elif stack and c == stack[-1]:
            stack.pop()
            if not stack:
                return i

        i += 1

    return -1


def split_top_level(text: str, separator: str = ",") -> list[str]:
    parts: list[str] = []
    depth = 0
    current: list[str] = []
    quote = ""
    for c in text:
        if quote:
            if c == quote:
                quote = ""
        elif c in "\"'`":
            quote = c
        elif c in "(<[{":
            depth += 1
        elif c in ")>]}":
            depth -= 1
        elif c == separator and depth == 0:
            parts.append("".join(current).strip())
            current = []
            continue

        current.append(c)

    tail = "".join(current).strip()
    if tail:
        parts.append(tail)

    return parts


def parse_fun_type(text: str) -> tuple[list[Param], list[Return]] | None:
    """`fun( a: T, b?: U ): R1, R2` -> params and returns, or `None` if not a function type."""
    text = text.strip()
    while text.startswith("(") and find_closing(text, 0) == len(text) - 1:
        text = text[1:-1].strip()

    if not text.startswith("fun"):
        return None

    open_at = text.find("(")
    if open_at < 0 or text[3:open_at].strip():
        return None

    close_at = find_closing(text, open_at)
    if close_at < 0:
        return None

    params: list[Param] = []
    for part in split_top_level(text[open_at + 1 : close_at]):
        name, _, typ = part.partition(":")
        name, typ = name.strip(), typ.strip()
        optional = name.endswith("?")
        params.append(Param(name=name.rstrip("?"), type=typ or "any", optional=optional))

    returns: list[Return] = []
    after = text[close_at + 1 :].strip()
    if after.startswith(":"):
        for part in split_top_level(after[1:]):
            name, colon, typ = part.partition(":")
            if colon and re.fullmatch(r"[A-Za-z_]\w*", name.strip()) and not typ.startswith(":"):
                returns.append(Return(type=typ.strip(), name=name.strip()))
            else:
                returns.append(Return(type=part.strip()))

    return params, returns


def is_optional_type(typ: str) -> bool:
    typ = typ.strip()
    return typ.endswith("?") or bool(re.search(r"(^|\|)\s*nil\s*($|\|)", typ))


# ---------------------------------------------------------------------------
# Parsing
# ---------------------------------------------------------------------------

REALM_RE = re.compile(r"^\[([A-Z /]+)\]\s*$")

FN_RE = re.compile(
    r"^((?:local\s+)?)function\s+([A-Za-z_][\w.]*)([.:])([A-Za-z_]\w*)\s*\(([^)]*)\)"
)
FN_GLOBAL_RE = re.compile(r"^((?:local\s+)?)function\s+([A-Za-z_]\w*)\s*\(([^)]*)\)")
ASSIGN_RE = re.compile(r"^([A-Za-z_][\w.]*)\s*=\s*(.+?)\s*;?\s*$")
LOCAL_TABLE_RE = re.compile(r"^local\s+([A-Za-z_]\w*)\s*=\s*\{\}")
LITERAL_RE = re.compile(r"^(?:-?\d[\w.+-]*|\"[^\"]*\"|'[^']*'|true|false)$")
PATH_RE = re.compile(r"^[A-Za-z_][\w.]*$")


def parse_doc_blocks(lines: list[str]) -> list[tuple[int, int, DocBlock]]:
    """Returns (start_idx, end_idx_exclusive, block) for contiguous --- groups."""
    blocks: list[tuple[int, int, DocBlock]] = []
    i = 0
    n = len(lines)

    while i < n:
        if not lines[i].startswith("---"):
            i += 1
            continue

        start = i
        desc_lines: list[str] = []
        tags: list[tuple[str, str]] = []
        variants: list[tuple[str, str]] = []
        realm = ""

        while i < n and lines[i].startswith("---"):
            raw = lines[i][3:]
            if raw[:1] in (" ", "\t"):
                raw = raw[1:]

            if raw.startswith("@"):
                space = raw.find(" ")
                if space == -1:
                    tags.append((raw[1:].strip(), ""))
                else:
                    tags.append((raw[1:space], raw[space + 1 :].strip()))
            elif raw.startswith("|") and tags and tags[-1][0] == "alias":
                body = raw[1:].strip()
                if body.startswith(">") or body.startswith("+"):
                    body = body[1:].strip()

                value, _, comment = body.partition("#")
                variants.append((value.strip(), comment.strip()))
            else:
                realm_match = REALM_RE.match(raw.strip())
                if realm_match and not desc_lines and not tags:
                    realm = realm_match.group(1).strip()
                elif raw.strip() == "":
                    if desc_lines:
                        desc_lines.append("")
                else:
                    desc_lines.append(raw)

            i += 1

        description = re.sub(r"\n{3,}", "\n\n", normalize_ws("\n".join(desc_lines)))
        blocks.append(
            (
                start,
                i,
                DocBlock(
                    description=description,
                    realm=realm,
                    tags=tags,
                    variants=variants,
                    start_line=start + 1,
                ),
            )
        )

    return blocks


def tag_map(block: DocBlock | None) -> dict[str, list[str]]:
    out: dict[str, list[str]] = defaultdict(list)
    if block is not None:
        for name, value in block.tags:
            out[name].append(value)

    return out


def visibility_from_tags(tags: dict[str, list[str]]) -> str:
    for visibility in ("private", "protected", "package"):
        if visibility in tags:
            return visibility

    return "public"


def deprecated_from_tags(tags: dict[str, list[str]]) -> str | None:
    values = tags.get("deprecated")
    if values is None:
        return None

    return values[0] or ""


def parse_params(tags: dict[str, list[str]]) -> list[Param]:
    params: list[Param] = []
    for value in tags.get("param", []):
        parts = value.split(None, 1)
        if len(parts) < 2:
            continue

        name = parts[0]
        typ, desc = split_type(parts[1])
        optional = name.endswith("?") or typ.endswith("?")
        params.append(
            Param(
                name=name.rstrip("?"),
                type=typ.removesuffix("?") if typ.endswith("?") and not typ.endswith(")?") else typ,
                description=desc,
                optional=optional,
            )
        )

    return params


def parse_returns(tags: dict[str, list[str]]) -> list[Return]:
    returns: list[Return] = []
    for value in tags.get("return", []):
        types, rest = split_type_list(value)
        if not types:
            continue

        name, desc = "", rest
        match = re.match(r"^([A-Za-z_]\w*|\.\.\.)(?:\s+(.*))?$", rest, re.S)
        if match and match.group(1) not in ("The", "A", "An", "Returns", "If", "True", "False"):
            name, desc = match.group(1), (match.group(2) or "")

        if desc.startswith("#"):
            desc = desc[1:].strip()

        for index, typ in enumerate(types):
            last = index == len(types) - 1
            returns.append(
                Return(type=typ, name=name if last else "", description=desc if last else "")
            )

    return returns


FIELD_HEAD_RE = re.compile(
    r"^(?:(public|protected|private|package)\s+)?(\[[^\]]+\]|[A-Za-z_]\w*)(\??)\s+(.*)$", re.S
)


def parse_fields(tags: dict[str, list[str]], realm: str, source: str, line: int) -> list[Field]:
    fields: list[Field] = []
    for value in tags.get("field", []):
        match = FIELD_HEAD_RE.match(value)
        if not match:
            continue

        vis, name, optional, rest = match.groups()
        typ, desc = split_type(rest)
        fields.append(
            Field(
                name=name,
                type=typ,
                description=desc,
                visibility=vis or "public",
                optional=bool(optional) or typ.endswith("?"),
                realm=realm,
                source=source,
                line=line,
            )
        )

    return fields


def preceding_block(blocks_by_end: dict[int, DocBlock], lines: list[str], line_idx: int) -> DocBlock | None:
    j = line_idx
    while j > 0 and lines[j - 1].strip() == "":
        j -= 1

    return blocks_by_end.get(j)


@dataclass
class ParsedFile:
    path: str
    classes: dict[str, ClassInfo] = field(default_factory=dict)
    aliases: list[AliasInfo] = field(default_factory=list)
    functions: list[Function] = field(default_factory=list)
    values: list[ValueDef] = field(default_factory=list)
    assignments: dict[str, int] = field(default_factory=dict)  # name -> line
    local_aliases: dict[str, str] = field(default_factory=dict)  # local stub -> class


def make_function(
    name: str,
    full: str,
    kind: str,
    receiver: str,
    block: DocBlock | None,
    rel: str,
    line: int,
) -> Function:
    tags = tag_map(block)
    return Function(
        name=name,
        full_name=full,
        kind=kind,
        receiver=receiver,
        params=parse_params(tags),
        returns=parse_returns(tags),
        description=block.description if block else "",
        realm=block.realm if block else "",
        overloads=list(tags.get("overload", [])),
        see=list(tags.get("see", [])),
        visibility=visibility_from_tags(tags),
        nodiscard="nodiscard" in tags,
        async_="async" in tags,
        deprecated=deprecated_from_tags(tags),
        source=rel,
        line=block.start_line if block else line,
    )


def parse_file(path: Path, root: Path) -> ParsedFile:
    rel = str(path.relative_to(root)).replace("\\", "/")
    text = path.read_text(encoding="utf-8", errors="replace")
    lines = text.splitlines()
    blocks = parse_doc_blocks(lines)
    blocks_by_end = {end: block for _, end, block in blocks}

    parsed = ParsedFile(path=rel)

    # first pass: class / alias annotations
    for _, end, block in blocks:
        tags = tag_map(block)

        for value in tags.get("alias", []):
            parts = value.split(None, 1)
            if not parts:
                continue

            parsed.aliases.append(
                AliasInfo(
                    name=parts[0],
                    definition=parts[1] if len(parts) > 1 else "",
                    description=block.description,
                    variants=list(block.variants),
                    source=rel,
                    line=block.start_line,
                )
            )

        for value in tags.get("class", []):
            match = re.match(r"^(?:\([^)]*\)\s*)?(.+?)(?:\s*:\s*(.+))?$", value)
            if not match:
                continue

            name = strip_generic(match.group(1).strip())
            parents = [strip_generic(p) for p in split_top_level(match.group(2) or "") if p]

            info = parsed.classes.get(name) or ClassInfo(name=name, source=rel, line=block.start_line)
            info.declared = True
            info.description = info.description or block.description
            info.realm = info.realm or block.realm
            info.parents = info.parents or parents
            info.fields.extend(parse_fields(tags, block.realm, rel, block.start_line))
            info.overloads.extend(tags.get("overload", []))
            info.operators.extend(tags.get("operator", []))
            info.see.extend(tags.get("see", []))
            if info.deprecated is None:
                info.deprecated = deprecated_from_tags(tags)

            parsed.classes[name] = info

            # bind the following local/global table for methods
            for k in range(end, min(end + 5, len(lines))):
                stripped = lines[k].strip()
                local_m = LOCAL_TABLE_RE.match(stripped)
                assign_m = ASSIGN_RE.match(stripped)
                if local_m:
                    parsed.local_aliases[local_m.group(1)] = name
                    break

                if assign_m and assign_m.group(2) == "{}":
                    parsed.assignments[assign_m.group(1)] = k + 1
                    break

    def resolve(path_name: str) -> str:
        head, dot, rest = path_name.partition(".")
        if head in parsed.local_aliases:
            return parsed.local_aliases[head] + dot + rest

        return path_name

    def bucket(name: str, line: int) -> ClassInfo:
        return parsed.classes.setdefault(name, ClassInfo(name=name, source=rel, line=line))

    # second pass: functions and assignments
    for idx, line in enumerate(lines):
        if not line or line[0] in " \t-":
            continue

        stripped = line.strip()
        block = preceding_block(blocks_by_end, lines, idx)

        fn_m = FN_RE.match(stripped)
        fn_g = None if fn_m else FN_GLOBAL_RE.match(stripped)

        if fn_m or fn_g:
            if fn_m:
                _, receiver, sep, fname, args = fn_m.groups()
                resolved = resolve(receiver)
                kind = "method" if sep == ":" else "static"
                full = f"{resolved}{sep}{fname}"
            else:
                _, fname, args = fn_g.groups()
                resolved = ""
                kind = "function"
                full = fname

            func = make_function(fname, full, kind, resolved, block, rel, idx + 1)

            # fill params from the stub if none annotated
            if not func.params and args.strip():
                for part in args.split(","):
                    part = part.strip()
                    if part:
                        func.params.append(Param(name=part, type="any"))

            if kind == "method":
                func.params = [p for p in func.params if p.name != "self"]

            parsed.functions.append(func)

            if resolved:
                info = bucket(resolved, func.line)
                (info.methods if kind == "method" else info.statics).append(func)

            continue

        assign_m = ASSIGN_RE.match(stripped)
        if not assign_m or stripped.startswith("local "):
            continue

        target, rhs = assign_m.group(1), assign_m.group(2)
        target = resolve(target)

        if rhs == "{}":
            parsed.assignments[target] = idx + 1

        tags = tag_map(block)
        if "class" in tags or ("alias" in tags and "type" not in tags):
            continue

        if PATH_RE.match(rhs) and rhs.split(".")[0] in parsed.local_aliases:
            # `input.cursor = cursor`, publishes a documented local table
            parsed.assignments[target] = idx + 1
            continue

        if rhs == "{}" and block is None:
            continue

        owner, _, key = target.rpartition(".")
        parsed.values.append(ValueDef(owner, key, rhs, block, rel, idx + 1))

    return parsed


# ---------------------------------------------------------------------------
# Classification
# ---------------------------------------------------------------------------

PRIMITIVE_TYPES = {
    "string",
    "number",
    "integer",
    "boolean",
    "table",
    "any",
    "nil",
    "self",
    "fun",
    "function",
    "thread",
    "userdata",
    "lightuserdata",
    "unknown",
}

EVENT_TYPES = {"Event", "Hook"}

# loader / engine namespaces, documented apart from the package environment
INTERNAL_ROOTS = {"dreamwork"}

# LuaLS names builtin library classes `<name>lib`, e.g. `stringlib`, `ffilib`
LUA_LIBRARIES = {
    "bit", "bit32", "buffer", "coroutine", "debug", "ffi", "io", "jit", "math", "os",
    "package", "string", "table", "utf8",
}


def inherits_object(name: str, classes: dict[str, ClassInfo], seen: set[str] | None = None) -> bool:
    seen = seen if seen is not None else set()
    if name in seen:
        return False

    seen.add(name)
    if name == "Object":
        return True

    info = classes.get(name)
    if not info:
        return False

    return any(inherits_object(parent, classes, seen) for parent in info.parents)


def is_class_companion(info: ClassInfo) -> bool:
    """True for constructible class tables (*Class / inherits Class)."""
    if info.name.endswith("Class") and info.name != "Class":
        return True

    return any(p == "Class" or p.endswith("Class") for p in info.parents)


def overload_instance_type(overload: str) -> str | None:
    parsed = parse_fun_type(overload)
    if not parsed or not parsed[1]:
        return None

    ret = strip_generic(parsed[1][0].type)
    if not re.fullmatch(r"[A-Za-z_][\w.]*", ret) or ret in PRIMITIVE_TYPES:
        return None

    return ret


def find_instance_from_class(info: ClassInfo) -> str | None:
    """Return instance type name if this is a *Class companion table."""
    if not is_class_companion(info):
        return None

    for overload in info.overloads:
        instance = overload_instance_type(overload)
        if instance:
            return instance

    for op in info.operators:
        m = re.match(r"call\s*(?:\(.*\))?\s*:\s*([A-Za-z_][\w.<>]*)", op)
        if m:
            ret = strip_generic(m.group(1))
            if ret not in PRIMITIVE_TYPES:
                return ret

    for p in info.parents:
        if p not in ("Class", "Object") and not p.endswith("Class"):
            return p

    if info.name.endswith("Class"):
        return info.name[: -len("Class")] or None

    return None


def looks_like_ctor_alias(name: str, classes: dict[str, ClassInfo]) -> str | None:
    """Map File/CRC16 assignment buckets to fs.File / checksum.CRC16 instances."""
    short = base_name(name)
    candidates = [n for n, c in classes.items() if c.is_class and base_name(n) == short]
    if len(candidates) == 1:
        return candidates[0]

    if name in classes and classes[name].is_class:
        return name

    return None


def merge_functions(target: list[Function], source: Iterable[Function]) -> None:
    known = {f.full_name for f in target}
    for func in source:
        if func.full_name not in known:
            target.append(func)
            known.add(func.full_name)


def classify(classes: dict[str, ClassInfo], assignments: dict[str, int]) -> None:
    companions: dict[str, str] = {}  # instance -> class companion

    for name, info in list(classes.items()):
        instance = find_instance_from_class(info)
        if instance:
            info.instance_of = instance
            companions[instance] = name

    for instance, companion in companions.items():
        if instance not in classes:
            classes[instance] = ClassInfo(name=instance, source=classes[companion].source)

        target = classes[instance]
        comp = classes[companion]
        target.is_class = True
        target.class_of = companion
        target.overloads = list(dict.fromkeys(target.overloads + comp.overloads))
        target.operators = list(dict.fromkeys(target.operators + comp.operators))
        target.description = target.description or comp.description
        target.realm = target.realm or comp.realm
        comp.is_class = False
        comp.is_library = False

    # constructor global names (File = {} for fs.File, CRC16 = {}, Queue = {})
    for instance, companion in companions.items():
        short = base_name(instance)
        ctor_name = next(
            (a for a in assignments if a == instance or a.endswith("." + short)), None
        ) or next((a for a in assignments if a == short), None)
        classes[instance].constructor = ctor_name or short

        merge_from = {instance, classes[instance].constructor, companion}
        for fname, finfo in list(classes.items()):
            if fname == instance:
                continue

            if fname in merge_from or (
                not finfo.is_class
                and not finfo.instance_of
                and not finfo.declared
                and base_name(fname) == short
                and (finfo.statics or finfo.methods)
            ):
                merge_functions(classes[instance].statics, finfo.statics)
                merge_functions(classes[instance].methods, finfo.methods)
                if fname not in (companion,) and not finfo.declared:
                    finfo.statics, finfo.methods = [], []

        # companion fields are static fields of the class
        for f in classes[companion].fields:
            if f.name.startswith("__") or any(x.name == f.name for x in classes[instance].fields):
                continue

            classes[instance].fields.append(f)

    # Object types with methods are classes even without a discovered companion
    for name, info in classes.items():
        if info.instance_of or info.is_class:
            continue

        if name in ("Object", "Class"):
            info.is_class = info.declared
            continue

        if name.endswith("Class"):
            continue

        if inherits_object(name, classes) and info.methods:
            info.is_class = True
            info.constructor = info.constructor or base_name(name)

    # merge LuaLS builtin *lib annotations (stringlib -> string, bitlib -> bit)
    for name, info in list(classes.items()):
        if name.endswith("lib") and len(name) > 3:
            short = name[: -len("lib")]
            if short in classes or short in assignments or base_name(short) in LUA_LIBRARIES:
                target = classes.setdefault(short, ClassInfo(name=short, source=info.source, line=info.line))
                target.description = target.description or info.description
                target.realm = target.realm or info.realm
                target.fields.extend(info.fields)
                merge_functions(target.statics, info.statics)
                info.instance_of = short  # hidden, links resolve to the library

    # libraries: namespaces with static APIs that are not class ctor aliases
    for name, info in classes.items():
        if info.instance_of or info.is_class or name.endswith("Class"):
            continue

        if inherits_object(name, classes):
            continue

        alias_of = looks_like_ctor_alias(name, classes)
        if alias_of and alias_of != name and not info.declared:
            target = classes[alias_of]
            merge_functions(target.statics, info.statics)
            merge_functions(target.methods, info.methods)
            if not target.constructor or target.constructor == base_name(alias_of):
                target.constructor = name if name in assignments else target.constructor

            info.instance_of = alias_of
            continue

        assigned = name in assignments
        lower = base_name(name)[:1].islower()
        if lower and (assigned or info.statics or info.overloads or info.fields or info.description or not info.declared):
            info.is_library = True
        elif assigned and info.statics and not info.declared:
            info.is_library = True
        elif info.declared and (info.description or info.fields or info.methods or info.operators):
            info.is_type = True


def attach_values(
    values: list[ValueDef],
    classes: dict[str, ClassInfo],
    functions_by_name: dict[str, Function],
    globals_fields: list[Field],
    globals_fns: list[Function],
) -> None:
    """Turns `owner.key = rhs` definitions into fields and function aliases."""
    for value in values:
        block = value.block
        tags = tag_map(block)
        type_text = split_type(tags["type"][0])[0] if tags.get("type") else ""
        description = block.description if block else ""
        realm = block.realm if block else ""
        full = f"{value.owner}.{value.key}" if value.owner else value.key

        # function typed fields: `---@type fun(): number` or `x.y = other.function`
        fun = parse_fun_type(type_text) if type_text else None
        target_fn = functions_by_name.get(value.rhs) if PATH_RE.match(value.rhs) else None

        if fun is not None or (target_fn is not None and not type_text):
            if target_fn is not None and fun is None:
                func = Function(
                    name=value.key,
                    full_name=full,
                    kind="static" if value.owner else "function",
                    receiver=value.owner,
                    params=list(target_fn.params),
                    returns=list(target_fn.returns),
                    description=description or target_fn.description,
                    realm=realm or target_fn.realm,
                    overloads=list(target_fn.overloads),
                    nodiscard=target_fn.nodiscard,
                    async_=target_fn.async_,
                    alias_of=value.rhs,
                    source=value.source,
                    line=value.line,
                )
            else:
                func = make_function(value.key, full, "static" if value.owner else "function",
                                     value.owner, block, value.source, value.line)
                if not func.params:
                    func.params = fun[0]
                if not func.returns:
                    func.returns = fun[1]

            if func.visibility != "public":
                continue

            if value.owner:
                merge_functions(
                    classes.setdefault(value.owner, ClassInfo(name=value.owner, source=value.source)).statics,
                    [func],
                )
            else:
                globals_fns.append(func)

            continue

        if block is None and not PATH_RE.match(value.rhs) and not LITERAL_RE.match(value.rhs):
            continue

        if block is None and value.rhs == "nil":
            continue

        if value.rhs == "{}" and not type_text:
            known = classes.get(full)
            if known is not None and (known.statics or known.methods or known.declared):
                # a namespace table: `string.PatternBytes = {}` + functions on it
                known.description = known.description or description
                known.realm = known.realm or realm
                continue

            type_text = "table"

        literal = value.rhs if LITERAL_RE.match(value.rhs) else ""
        alias_of = value.rhs if not literal and value.rhs not in ("nil", "{}") and PATH_RE.match(value.rhs) else ""

        if not type_text and literal:
            if literal in ("true", "false"):
                type_text = "boolean"
            elif literal[:1] in "\"'":
                type_text = "string"
            else:
                type_text = "integer" if re.fullmatch(r"-?\d+", literal) else "number"

        if not type_text and alias_of:
            type_text = alias_of

        entry = Field(
            name=value.key,
            type=type_text,
            description=description,
            visibility=visibility_from_tags(tags),
            realm=realm,
            value=literal,
            alias_of=alias_of,
            source=value.source,
            line=value.line,
        )

        if entry.visibility != "public":
            continue

        if not value.owner:
            globals_fields.append(entry)
            continue

        owner = classes.setdefault(value.owner, ClassInfo(name=value.owner, source=value.source))
        existing = next((f for f in owner.fields if f.name == entry.name), None)
        if existing is None:
            owner.fields.append(entry)
        else:
            existing.type = existing.type or entry.type
            existing.description = existing.description or entry.description
            existing.realm = existing.realm or entry.realm
            existing.value = existing.value or entry.value
            existing.alias_of = existing.alias_of or entry.alias_of


def build_libraries(
    classes: dict[str, ClassInfo],
    free_functions: list[Function],
    global_fields: list[Field],
) -> dict[str, LibraryInfo]:
    libraries: dict[str, LibraryInfo] = {}

    for name, info in classes.items():
        if not info.is_library:
            continue

        if not (info.statics or info.fields or info.declared):
            continue

        libraries[name] = LibraryInfo(
            name=name,
            description=info.description,
            realm=info.realm,
            functions=[f for f in info.statics if f.visibility == "public"],
            fields=[f for f in info.fields if f.visibility == "public"],
            see=list(info.see),
            source=info.source,
            line=info.line,
        )

    # every dotted prefix of a page gets a namespace page
    page_names = set(libraries) | {n for n, c in classes.items() if c.is_class or c.is_type}
    for name in sorted(page_names):
        prefix = name
        while "." in prefix:
            prefix = prefix.rsplit(".", 1)[0]
            if prefix in page_names or not base_name(prefix)[:1].islower():
                break

            known = classes.get(prefix)
            libraries[prefix] = LibraryInfo(
                name=prefix,
                description=(known.description if known else "") or f"Namespace `{prefix}`.",
                realm=known.realm if known else "",
            )
            page_names.add(prefix)

    for name, info in classes.items():
        if not (info.is_class or info.is_type) or "." not in name:
            continue

        prefix = name.rsplit(".", 1)[0]
        if prefix in libraries:
            libraries[prefix].nested_classes.append(name)

    merged_globals: dict[str, Field] = {}
    for f in global_fields:
        known = merged_globals.setdefault(f.name, f)
        if known is not f:
            known.description = known.description or f.description
            known.realm = known.realm or f.realm
            if known.type in ("", "table") or known.alias_of:
                known.type = f.type or known.type

    global_fields = list(merged_globals.values())
    globals_fn = [f for f in free_functions if f.kind == "function" and f.visibility == "public"]
    if globals_fn or global_fields:
        libraries["_G"] = LibraryInfo(
            name="_G",
            description="Global functions and values of the dreamwork environment.",
            functions=globals_fn,
            fields=global_fields,
        )

    for lib in libraries.values():
        lib.nested_classes = sorted(set(lib.nested_classes), key=str.lower)
        seen: dict[str, Function] = {}
        for fn in lib.functions:
            seen.setdefault(fn.full_name, fn)

        lib.functions = sorted(seen.values(), key=lambda f: f.full_name.lower())

    return libraries


# ---------------------------------------------------------------------------
# Site model: pages, links and navigation
# ---------------------------------------------------------------------------


def slugify(name: str) -> str:
    return re.sub(r"[^\w.-]+", "_", name)


@dataclass
class Page:
    name: str
    kind: str  # globals | library | class | type | aliases | index
    href: str
    title: str
    summary: str = ""


@dataclass
class NavNode:
    segment: str
    full_name: str
    page: Page | None = None
    children: dict[str, "NavNode"] = field(default_factory=dict)


class Site:
    def __init__(
        self,
        libraries: dict[str, LibraryInfo],
        classes: dict[str, ClassInfo],
        aliases: list[AliasInfo],
        repo_url: str,
        source_ref: str,
    ):
        self.libraries = libraries
        self.classes = classes
        self.aliases = {a.name: a for a in sorted(aliases, key=lambda a: a.name.lower())}
        self.repo_url = repo_url.rstrip("/")
        self.source_ref = source_ref

        self.pages: dict[str, Page] = {}
        used_paths: set[str] = set()

        def page_path(directory: str, name: str) -> str:
            # case-insensitive filesystems: `Client` / `client` must not share a file
            slug = slugify(name)
            candidate, n = slug, 1
            while f"{directory}/{candidate}".lower() in used_paths:
                n += 1
                candidate = f"{slug}-{n}"

            used_paths.add(f"{directory}/{candidate}".lower())
            return f"{directory}/{candidate}.html"

        self.type_links: dict[str, str] = {}  # type name -> href (root relative)
        self.symbol_links: dict[str, str] = {}  # `lib.fn`, `Class:method` -> href
        self.subclasses: dict[str, list[str]] = defaultdict(list)

        for name, lib in libraries.items():
            title = "Globals" if name == "_G" else name
            self.pages[name] = Page(name, "globals" if name == "_G" else "library",
                                    page_path("library", name), title, first_sentence(lib.description))

        for name, info in classes.items():
            if info.is_class or info.is_type:
                if name in self.pages:  # library and type share the name, the library wins
                    continue

                self.pages[name] = Page(name, "class" if info.is_class else "type",
                                        page_path("class", name), name, first_sentence(info.description))

        if self.aliases:
            self.pages["@aliases"] = Page("@aliases", "aliases", "aliases.html", "Aliases")

        for name, page in self.pages.items():
            if page.kind in ("library", "class", "type"):
                self.type_links[name] = page.href
                self.symbol_links[name] = page.href

        for name, info in classes.items():
            if info.instance_of and info.instance_of in self.pages:
                self.type_links.setdefault(name, self.pages[info.instance_of].href)

            for parent in info.parents:
                if info.is_class or info.is_type:
                    self.subclasses[parent].append(name)

        for name in self.aliases:
            self.type_links.setdefault(name, f"aliases.html#{alias_anchor(name)}")

        for lib in libraries.values():
            page = self.pages[lib.name]
            for fn in lib.functions:
                self.symbol_links.setdefault(fn.full_name, f"{page.href}#{member_anchor(fn)}")

            for f in lib.fields:
                key = f.name if lib.name == "_G" else f"{lib.name}.{f.name}"
                self.symbol_links.setdefault(key, f"{page.href}#{field_anchor(f.name)}")

        for name, info in classes.items():
            page = self.pages.get(name)
            if page is None or page.kind not in ("class", "type"):
                continue

            for fn in info.methods + info.statics:
                if fn.visibility == "public":
                    anchor = f"{page.href}#{member_anchor(fn)}"
                    self.symbol_links.setdefault(fn.full_name, anchor)
                    self.symbol_links.setdefault(f"{name}{':' if fn.kind == 'method' else '.'}{fn.name}", anchor)

            for f in info.fields:
                self.symbol_links.setdefault(f"{name}.{f.name}", f"{page.href}#{field_anchor(f.name)}")

        self.nav_roots = self.build_nav()
        self.order = self.flatten_nav()

    # -- navigation -----------------------------------------------------------

    def build_nav(self) -> dict[str, list[NavNode]]:
        roots: dict[str, dict[str, NavNode]] = {"libraries": {}, "classes": {}, "types": {}, "internal": {}}

        def insert(group: dict[str, NavNode], page: Page) -> None:
            parts = page.name.split(".")
            cursor = group
            node: NavNode | None = None
            for depth, part in enumerate(parts):
                key = ".".join(parts[: depth + 1])
                node = cursor.setdefault(part, NavNode(part, key))
                cursor = node.children

            assert node is not None
            node.page = page

        def internal(page: Page) -> bool:
            return page.name.split(".")[0] in INTERNAL_ROOTS

        for page in self.pages.values():
            if page.kind == "library":
                insert(roots["internal" if internal(page) else "libraries"], page)

        # nested classes go under their library / class when it is in the same tree
        for page in sorted(self.pages.values(), key=lambda p: p.name.count(".")):
            if page.kind not in ("class", "type"):
                continue

            group = "classes" if page.kind == "class" else "types"
            head = page.name.split(".")[0]
            if internal(page):
                insert(roots["internal"], page)
            elif head in roots["libraries"] and page.kind == "class":
                insert(roots["libraries"], page)
            else:
                insert(roots[group], page)

        def ordered(mapping: dict[str, NavNode]) -> list[NavNode]:
            nodes = sorted(mapping.values(), key=lambda n: (n.segment[:1].isupper(), n.segment.lower()))
            for node in nodes:
                node.children = {c.segment: c for c in ordered(node.children)}

            return nodes

        return {name: ordered(group) for name, group in roots.items()}

    def flatten_nav(self) -> list[Page]:
        order = [p for p in (self.pages.get("_G"),) if p]

        def walk(nodes: Iterable[NavNode]) -> None:
            for node in nodes:
                if node.page:
                    order.append(node.page)

                walk(node.children.values())

        for group in ("libraries", "classes", "types", "internal"):
            walk(self.nav_roots[group])

        if "@aliases" in self.pages:
            order.append(self.pages["@aliases"])

        return order

    # -- links ----------------------------------------------------------------

    def source_link(self, source: str, line: int) -> str:
        if not self.repo_url or not source:
            return ""

        return f"{self.repo_url}/blob/{self.source_ref}/library/{source}#L{line}"

    def type_href(self, name: str) -> str | None:
        name = strip_generic(name).rstrip("?").removesuffix("[]")
        if name in PRIMITIVE_TYPES:
            return None

        href = self.type_links.get(name)
        if href is None and name.endswith("lib"):
            href = self.type_links.get(name[:-3])

        return href

    def symbol_href(self, text: str) -> str | None:
        text = re.sub(r"\(.*\)$", "", text.strip())
        if not re.fullmatch(r"[A-Za-z_][\w.:]*", text):
            return None

        # a bare lowercase word is usually a variable (`path`, `string`), not the library
        if "." not in text and ":" not in text and not text[:1].isupper():
            return None

        return self.symbol_links.get(text) or self.type_links.get(text)


def member_anchor(fn: Function) -> str:
    return slugify(fn.full_name.replace(":", "-"))


def field_anchor(name: str) -> str:
    return "field-" + slugify(name.strip("[]"))


def alias_anchor(name: str) -> str:
    return "alias-" + slugify(name)


# ---------------------------------------------------------------------------
# HTML helpers
# ---------------------------------------------------------------------------

TYPE_TOKEN_RE = re.compile(r"(\"[^\"]*\"|'[^']*'|`[^`]*`)|([A-Za-z_][\w.]*(?:\[\])?)")


def render_type(site: Site, typ: str, base: str) -> str:
    """Escapes a type expression and links every known type name in it."""
    out: list[str] = []
    last = 0
    for match in TYPE_TOKEN_RE.finditer(typ):
        out.append(escape(typ[last : match.start()]))
        last = match.end()
        token = match.group(0)
        if match.group(1):
            out.append(f'<span class="t-str">{escape(token)}</span>')
            continue

        href = site.type_href(token)
        if href:
            out.append(f'<a class="t-link" href="{escape(base + href)}">{escape(token)}</a>')
        elif token in PRIMITIVE_TYPES or token.removesuffix("[]") in PRIMITIVE_TYPES:
            out.append(f'<span class="t-prim">{escape(token)}</span>')
        else:
            out.append(escape(token))

    out.append(escape(typ[last:]))
    return "".join(out)


LUA_KEYWORDS = {
    "and", "break", "do", "else", "elseif", "end", "false", "for", "function", "goto", "if",
    "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while",
    "continue",
}

LUA_TOKEN_RE = re.compile(
    r"(?P<comment>--\[(?P<eq>=*)\[.*?\](?P=eq)\]|--[^\n]*)"
    r"|(?P<string>\[(?P<eq2>=*)\[.*?\](?P=eq2)\]|\"(?:\\.|[^\"\\\n])*\"|'(?:\\.|[^'\\\n])*')"
    r"|(?P<number>\b0[xX][\da-fA-F]+(?:[uU]?[lL]{2}|[iI])?\b|\b\d+(?:\.\d*)?(?:[eE][+-]?\d+)?\b)"
    r"|(?P<name>[A-Za-z_]\w*)",
    re.S,
)


def highlight_lua(code: str) -> str:
    out: list[str] = []
    last = 0
    for match in LUA_TOKEN_RE.finditer(code):
        out.append(escape(code[last : match.start()]))
        last = match.end()
        text = escape(match.group(0))
        if match.group("comment"):
            out.append(f'<span class="hl-c">{text}</span>')
        elif match.group("string"):
            out.append(f'<span class="hl-s">{text}</span>')
        elif match.group("number"):
            out.append(f'<span class="hl-n">{text}</span>')
        elif match.group(0) in LUA_KEYWORDS:
            out.append(f'<span class="hl-k">{text}</span>')
        elif code[match.end() : match.end() + 1] == "(":
            out.append(f'<span class="hl-f">{text}</span>')
        else:
            out.append(text)

    out.append(escape(code[last:]))
    return "".join(out)


SAFE_URL_RE = re.compile(r"^(https?://|mailto:|#|\.{0,2}/|[\w.-]+\.html)", re.I)


def md_inline(site: Site, text: str, base: str) -> str:
    """Escapes and applies inline markdown: code, links, bold, italic."""
    if not text:
        return ""

    placeholders: list[str] = []

    def hold(snippet: str) -> str:
        placeholders.append(snippet)
        return f"\x00{len(placeholders) - 1}\x00"

    def code_repl(match: re.Match[str]) -> str:
        code = match.group(1)
        href = site.symbol_href(code)
        if href:
            return hold(f'<a class="code-link" href="{escape(base + href)}"><code>{escape(code)}</code></a>')

        return hold(f"<code>{escape(code)}</code>")

    text = re.sub(r"`([^`\n]+)`", code_repl, text)

    def link_repl(match: re.Match[str]) -> str:
        label, url = match.group(1), match.group(2)
        if not SAFE_URL_RE.match(url):
            return hold(escape(label))

        external = url.lower().startswith(("http://", "https://"))
        rel = ' rel="noopener noreferrer" target="_blank"' if external else ""
        return hold(f'<a href="{escape(url)}"{rel}>{escape(label)}</a>')

    text = re.sub(r"\[([^\]]+)\]\(([^)\s]+)\)", link_repl, text)
    text = re.sub(r"(?<![\"(=])\bhttps?://[^\s<>()]+[^\s<>().,;:!?]",
                  lambda m: hold(f'<a href="{escape(m.group(0))}" rel="noopener noreferrer" target="_blank">'
                                 f"{escape(m.group(0))}</a>"), text)

    text = escape(text)

    # asterisks survive escaping, underscores only count around words (not snake_case)
    text = re.sub(r"\*\*(?=\S)(.+?)(?<=\S)\*\*", r"<strong>\1</strong>", text)
    text = re.sub(r"(?<![\w*])\*(?=\S)([^*\n]+?)(?<=\S)\*(?![\w*])", r"<em>\1</em>", text)
    text = re.sub(r"(?<!\w)__(?=\S)(.+?)(?<=\S)__(?!\w)", r"<strong>\1</strong>", text)
    text = re.sub(r"(?<!\w)_(?=[^\s_])([^_\n]+?)(?<=[^\s_])_(?!\w)", r"<em>\1</em>", text)

    # held snippets may hold others, e.g. code spans inside a link label
    while "\x00" in text:
        text = re.sub(r"\x00(\d+)\x00", lambda m: placeholders[int(m.group(1))], text)

    return text


def _is_table_row(line: str) -> bool:
    stripped = line.strip()
    return stripped.startswith("|") and stripped.endswith("|") and len(stripped) > 1


def _is_table_sep(line: str) -> bool:
    return _is_table_row(line) and re.fullmatch(r"[\s|:-]+", line.strip()) is not None and "-" in line


def _parse_table_row(line: str) -> list[str]:
    return [c.strip() for c in line.strip()[1:-1].split("|")]


LIST_RE = re.compile(r"^(\s*)([-*+]|\d+\.)\s+")


def _starts_block(lines: list[str], i: int) -> bool:
    peek = lines[i]
    return bool(
        peek.strip().startswith("```")
        or re.match(r"^#{1,4}\s+", peek)
        or re.match(r"^(\*{3,}|-{3,}|_{3,})\s*$", peek.strip())
        or peek.lstrip().startswith(">")
        or LIST_RE.match(peek)
        or (i + 1 < len(lines) and _is_table_row(peek) and _is_table_sep(lines[i + 1]))
    )


def render_blocks(site: Site, text: str, base: str) -> str:
    """Renders the markdown subset used in EmmyLua docs."""
    if not text:
        return ""

    lines = text.replace("\r\n", "\n").replace("\r", "\n").split("\n")
    out: list[str] = []
    i = 0
    n = len(lines)

    while i < n:
        line = lines[i]
        stripped = line.strip()

        fence = re.match(r"^```\s*([\w+-]*)\s*$", stripped)
        if fence:
            lang = fence.group(1) or "lua"
            i += 1
            code_lines: list[str] = []
            while i < n and lines[i].strip() != "```":
                code_lines.append(lines[i])
                i += 1

            i += 1
            code = "\n".join(code_lines)
            body = highlight_lua(code) if lang.lower() in ("lua", "luau", "moon") else escape(code)
            out.append(
                f'<div class="code-block"><div class="code-head"><span>{escape(lang)}</span>'
                f'<button type="button" class="copy-btn" aria-label="Copy code">Copy</button></div>'
                f"<pre><code>{body}</code></pre></div>"
            )
            continue

        heading = re.match(r"^(#{1,4})\s+(.+)$", line)
        if heading:
            level = min(len(heading.group(1)) + 2, 6)
            out.append(f"<h{level}>{md_inline(site, heading.group(2).strip(), base)}</h{level}>")
            i += 1
            continue

        if re.match(r"^(\*{3,}|-{3,}|_{3,})\s*$", stripped):
            out.append("<hr>")
            i += 1
            continue

        if line.lstrip().startswith(">"):
            quote: list[str] = []
            while i < n and lines[i].lstrip().startswith(">"):
                quote.append(re.sub(r"^\s*>\s?", "", lines[i]))
                i += 1

            kind = "note"
            if quote and re.match(r"^\[!(\w+)\]\s*$", quote[0].strip()):
                kind = quote.pop(0).strip()[2:-1].lower()

            out.append(f'<blockquote class="hint hint-{escape(kind)}">{render_blocks(site, chr(10).join(quote), base)}</blockquote>')
            continue

        if i + 1 < n and _is_table_row(line) and _is_table_sep(lines[i + 1]):
            headers = _parse_table_row(line)
            i += 2
            rows: list[list[str]] = []
            while i < n and _is_table_row(lines[i]):
                rows.append(_parse_table_row(lines[i]))
                i += 1

            thead = "".join(f"<th>{md_inline(site, h, base)}</th>" for h in headers)
            tbody = "".join(
                "<tr>" + "".join(f"<td>{md_inline(site, c, base)}</td>"
                                 for c in (row + [""] * len(headers))[: len(headers)]) + "</tr>"
                for row in rows
            )
            out.append(f'<div class="table-wrap"><table><thead><tr>{thead}</tr></thead><tbody>{tbody}</tbody></table></div>')
            continue

        list_m = LIST_RE.match(line)
        if list_m:
            ordered = list_m.group(2)[0].isdigit()
            items: list[str] = []
            while i < n and lines[i].strip():
                item_m = LIST_RE.match(lines[i])
                if item_m:
                    items.append(lines[i][item_m.end() :])
                elif items and not _starts_block(lines, i):
                    items[-1] += " " + lines[i].strip()  # wrapped item
                else:
                    break

                i += 1

            tag = "ol" if ordered else "ul"
            out.append(f"<{tag}>" + "".join(f"<li>{md_inline(site, item, base)}</li>" for item in items) + f"</{tag}>")
            continue

        if not stripped:
            i += 1
            continue

        para: list[str] = []
        while i < n and lines[i].strip():
            if para and _starts_block(lines, i):
                break

            para.append(lines[i].strip())
            i += 1

        out.append(f"<p>{md_inline(site, ' '.join(para), base)}</p>")

    return "".join(out)


def render_markdown(site: Site, text: str, base: str) -> str:
    if not text:
        return ""

    return f'<div class="prose">{render_blocks(site, text, base)}</div>'


def first_sentence(text: str, limit: int = 160) -> str:
    if not text:
        return ""

    para = text.strip().split("\n\n", 1)[0]
    para = " ".join(line.strip() for line in para.split("\n") if not line.strip().startswith("```"))
    para = re.sub(r"`([^`]+)`", r"\1", para)
    para = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", para)
    para = re.sub(r"\*\*|(?<!\w)__|__(?!\w)", "", para)
    match = re.match(r"^(.+?[.!?])(?=\s+[A-Z`(\[]|$)", para)
    if match and len(match.group(1)) >= 20:
        para = match.group(1)

    if len(para) > limit:
        return para[: limit - 1].rstrip() + "…"

    return para


REALM_KINDS = {"SHARED": "shared", "SERVER": "server", "CLIENT": "client", "MENU": "menu"}


def realm_badges(realm: str) -> str:
    if not realm:
        return ""

    parts = [p for p in re.split(r"\s+AND\s+|\s*/\s*|\s+", realm.upper()) if p]
    badges = []
    for part in parts:
        kind = REALM_KINDS.get(part)
        if kind:
            badges.append(f'<span class="realm realm-{kind}" title="{escape(realm.title())}">{kind}</span>')

    return f'<span class="realms">{"".join(badges)}</span>' if badges else ""


def badge(text: str, cls: str = "") -> str:
    return f'<span class="badge {cls}">{escape(text)}</span>'


# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------


@dataclass
class TocEntry:
    anchor: str
    label: str
    level: int = 2


class Renderer:
    def __init__(self, site: Site, out: Path):
        self.site = site
        self.out = out
        self.search: list[dict[str, str]] = []
        self.anchors: dict[str, set[str]] = defaultdict(set)

    # -- shell ----------------------------------------------------------------

    def nav_html(self, base: str, active: str) -> str:
        active_page = self.site.pages.get(active)
        active_name = active_page.name if active_page else ""

        def render(nodes: list[NavNode]) -> str:
            parts: list[str] = []
            for node in nodes:
                children = list(node.children.values())
                is_active = node.page is not None and node.page.name == active_name
                in_path = active_name == node.full_name or active_name.startswith(node.full_name + ".")
                classes = ["nav-item"]
                if children and in_path:
                    classes.append("open")

                icon = ""
                if node.page and node.page.kind in ("class", "type"):
                    icon = f'<span class="nav-icon nav-{node.page.kind}">{"C" if node.page.kind == "class" else "T"}</span>'

                label = f"{icon}<span>{escape(node.segment)}</span>"
                if node.page:
                    current = ' aria-current="page" class="active"' if is_active else ""
                    link = f'<a href="{escape(base + node.page.href)}"{current}>{label}</a>'
                else:
                    link = f'<span class="nav-label">{label}</span>'

                twist = (
                    f'<button type="button" class="nav-twist" aria-expanded="{"true" if children and in_path else "false"}" '
                    f'aria-label="Toggle {escape(node.full_name)}"></button>'
                    if children
                    else '<span class="nav-twist-pad"></span>'
                )
                child_html = f'<ul class="nav-tree">{render(children)}</ul>' if children else ""
                parts.append(f'<li class="{" ".join(classes)}"><div class="nav-row">{twist}{link}</div>{child_html}</li>')

            return "".join(parts)

        def single(page: Page | None, label: str) -> str:
            if page is None:
                return ""

            current = ' aria-current="page" class="active"' if page.name == active_name or page.kind == active else ""
            return (
                f'<li class="nav-item"><div class="nav-row"><span class="nav-twist-pad"></span>'
                f'<a href="{escape(base + page.href)}"{current}><span>{escape(label)}</span></a></div></li>'
            )

        index_current = ' aria-current="page" class="active"' if active == "index" else ""
        groups = [
            '<div class="nav-group"><ul class="nav-tree">'
            f'<li class="nav-item"><div class="nav-row"><span class="nav-twist-pad"></span>'
            f'<a href="{escape(base)}index.html"{index_current}><span>Overview</span></a></div></li>'
            f'{single(self.site.pages.get("_G"), "Globals")}'
            f'{single(self.site.pages.get("@aliases"), "Aliases")}'
            "</ul></div>"
        ]
        for key, title in (("libraries", "Libraries"), ("classes", "Classes"), ("types", "Types"), ("internal", "Internal")):
            nodes = self.site.nav_roots[key]
            if nodes:
                groups.append(f'<div class="nav-group"><div class="nav-title">{title}</div><ul class="nav-tree">{render(nodes)}</ul></div>')

        return "".join(groups)

    def page_shell(self, page: Page | None, title: str, body: str, toc: list[TocEntry], base: str) -> str:
        active = page.name if page else "index"
        toc_html = ""
        if toc:
            items = "".join(
                f'<li class="toc-l{entry.level}"><a href="#{escape(entry.anchor)}">{escape(entry.label)}</a></li>'
                for entry in toc
            )
            toc_html = f'<aside class="toc"><div class="toc-title">On this page</div><ul>{items}</ul></aside>'

        pager = ""
        if page is not None and page in self.site.order:
            index = self.site.order.index(page)
            prev_page = self.site.order[index - 1] if index > 0 else None
            next_page = self.site.order[index + 1] if index + 1 < len(self.site.order) else None
            cells = []
            if prev_page:
                cells.append(f'<a class="pager-prev" href="{escape(base + prev_page.href)}"><span>Previous</span>{escape(prev_page.title)}</a>')
            else:
                cells.append("<span></span>")

            if next_page:
                cells.append(f'<a class="pager-next" href="{escape(base + next_page.href)}"><span>Next</span>{escape(next_page.title)}</a>')

            pager = f'<nav class="pager">{"".join(cells)}</nav>'

        repo = ""
        if self.site.repo_url:
            repo = f'<a class="top-link" href="{escape(self.site.repo_url)}" rel="noopener noreferrer">GitHub</a>'

        description = escape(page.summary if page and page.summary else "dreamwork API reference")

        return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description" content="{description}">
<title>{escape(title)} · dreamwork</title>
<script>document.documentElement.dataset.theme=localStorage.getItem("dw-theme")||(matchMedia("(prefers-color-scheme: dark)").matches?"dark":"light")</script>
<link rel="stylesheet" href="{escape(base)}assets/style.css">
</head>
<body data-base="{escape(base)}">
<header class="topbar">
  <button class="menu-toggle" id="menu-toggle" type="button" aria-label="Toggle navigation">☰</button>
  <a class="brand" href="{escape(base)}index.html">dream<span>work</span><small>API</small></a>
  <div class="search-wrap">
    <input id="doc-search" type="search" placeholder="Search…" autocomplete="off" spellcheck="false" aria-label="Search the API">
    <kbd class="search-kbd">Ctrl K</kbd>
    <div id="search-results" class="search-results" role="listbox"></div>
  </div>
  <div class="top-actions">{repo}<button class="theme-toggle" id="theme-toggle" type="button" aria-label="Toggle dark mode"></button></div>
</header>
<div class="layout">
<nav class="sidebar" id="sidebar" aria-label="API navigation">{self.nav_html(base, active)}</nav>
<main class="content" id="content">
<article class="page">
{body}
</article>
{pager}
<footer class="page-foot">Generated from the dreamwork <code>meta</code> branch.</footer>
</main>
{toc_html}
</div>
<script src="{escape(base)}assets/app.js"></script>
</body>
</html>
"""

    def write(self, page: Page | None, href: str, title: str, body: str, toc: list[TocEntry]) -> None:
        base = "../" * href.count("/")
        html_text = self.page_shell(page, title, body, toc, base)
        target = self.out / href
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(html_text, encoding="utf-8")
        self.anchors[href].update(re.findall(r'\sid="([^"]+)"', html_text))

    def add_search(self, name: str, full: str, kind: str, href: str, summary: str = "") -> None:
        self.search.append({"n": name, "f": full, "k": kind, "h": href, "s": first_sentence(summary, 120)})

    # -- pieces ---------------------------------------------------------------

    def crumbs(self, name: str, base: str, kind: str) -> str:
        parts = [f'<a href="{base}index.html">Docs</a>']
        segments = name.split(".")
        for depth in range(1, len(segments)):
            prefix = ".".join(segments[:depth])
            page = self.site.pages.get(prefix)
            label = escape(segments[depth - 1])
            parts.append(f'<a href="{escape(base + page.href)}">{label}</a>' if page else f"<span>{label}</span>")

        parts.append(f"<span>{escape(segments[-1])}</span>")
        return f'<div class="crumbs"><span class="crumb-kind">{escape(kind)}</span>{" / ".join(parts)}</div>'

    def signature(self, fn: Function, base: str, display: str | None = None, keyword: bool = True) -> str:
        params = []
        for p in fn.params:
            name = escape(p.name) + ("?" if p.optional else "")
            params.append(f'<span class="s-param">{name}</span>: {render_type(self.site, p.type, base)}' if p.type else name)

        returns = ""
        if fn.returns:
            types = [r.type for r in fn.returns]
            if len(types) > 1:
                types = [f"({t})" if t.startswith("fun(") else t for t in types]

            returns = ": " + ", ".join(render_type(self.site, t, base) for t in types)

        prefix = '<span class="hl-k">async</span> ' if fn.async_ else ""
        name = escape(display or fn.full_name)
        if keyword:
            prefix += '<span class="hl-k">function</span> '

        return f'<pre class="sig"><code>{prefix}<span class="s-name">{name}</span>({", ".join(params)}){returns}</code></pre>'

    def overload_sig(self, name: str, overload: str, base: str, keyword: bool = True) -> str:
        parsed = parse_fun_type(overload)
        if parsed is None:
            return f'<pre class="sig"><code>{escape(name)} {render_type(self.site, overload, base)}</code></pre>'

        params, returns = parsed
        fn = Function(name=name, full_name=name, kind="function", params=params, returns=returns)
        return self.signature(fn, base, keyword=keyword)

    def params_table(self, params: list[Param], base: str) -> str:
        if not params:
            return ""

        rows = "".join(
            f'<tr><td><code class="p-name">{escape(p.name)}</code>{"<span class=opt>optional</span>" if p.optional else ""}</td>'
            f'<td><code>{render_type(self.site, p.type, base)}</code></td>'
            f"<td>{md_inline(self.site, p.description, base)}</td></tr>"
            for p in params
        )
        return f'<div class="sub-title">Parameters</div><div class="table-wrap"><table class="api"><thead><tr><th>Name</th><th>Type</th><th>Description</th></tr></thead><tbody>{rows}</tbody></table></div>'

    def returns_table(self, returns: list[Return], base: str) -> str:
        if not returns:
            return ""

        rows = "".join(
            f'<tr><td><code>{render_type(self.site, r.type, base)}</code></td>'
            f'<td>{f"<code class=p-name>{escape(r.name)}</code>" if r.name else ""}</td>'
            f"<td>{md_inline(self.site, r.description, base)}</td></tr>"
            for r in returns
        )
        return f'<div class="sub-title">Returns</div><div class="table-wrap"><table class="api"><thead><tr><th>Type</th><th>Name</th><th>Description</th></tr></thead><tbody>{rows}</tbody></table></div>'

    def see_also(self, see: list[str], base: str) -> str:
        if not see:
            return ""

        items = []
        for value in see:
            target, _, note = value.partition(" ")
            href = self.site.symbol_href(target) or self.site.type_href(target)
            code = f"<code>{escape(target)}</code>"
            link = f'<a class="code-link" href="{escape(base + href)}">{code}</a>' if href else code
            items.append(f"<li>{link} {md_inline(self.site, note, base)}</li>")

        return f'<div class="sub-title">See also</div><ul class="see">{"".join(items)}</ul>'

    def source_link(self, source: str, line: int) -> str:
        url = self.site.source_link(source, line)
        return f'<a class="src-link" href="{escape(url)}" rel="noopener noreferrer" title="View definition">source</a>' if url else ""

    def deprecated_note(self, deprecated: str | None, base: str) -> str:
        if deprecated is None:
            return ""

        text = md_inline(self.site, deprecated, base) if deprecated else "This API is deprecated and may be removed."
        return f'<blockquote class="hint hint-warning"><p><strong>Deprecated.</strong> {text}</p></blockquote>'

    def function_block(self, fn: Function, base: str, display_name: str | None = None) -> str:
        anchor = member_anchor(fn)
        tags = [realm_badges(fn.realm)]
        if fn.async_:
            tags.append(badge("async", "b-async"))
        if fn.nodiscard:
            tags.append(badge("nodiscard"))
        if fn.deprecated is not None:
            tags.append(badge("deprecated", "b-warn"))

        alias = ""
        if fn.alias_of:
            href = self.site.symbol_href(fn.alias_of)
            target = f"<code>{escape(fn.alias_of)}</code>"
            alias = f'<p class="alias-note">Alias of {f"<a class=code-link href={chr(34)}{escape(base + href)}{chr(34)}>{target}</a>" if href else target}.</p>'

        overloads = ""
        if fn.overloads:
            overloads = '<div class="sub-title">Overloads</div>' + "".join(
                self.overload_sig(fn.full_name, o, base) for o in fn.overloads
            )

        title = display_name or fn.full_name
        return f"""
<section class="member" id="{escape(anchor)}">
  <div class="member-head">
    <h3><a class="anchor" href="#{escape(anchor)}" aria-label="Link to {escape(title)}">#</a>{escape(title)}</h3>
    <div class="member-tags">{''.join(tags)}{self.source_link(fn.source, fn.line)}</div>
  </div>
  {self.signature(fn, base)}
  {self.deprecated_note(fn.deprecated, base)}
  {alias}
  {render_markdown(self.site, fn.description, base)}
  {self.params_table(fn.params, base)}
  {self.returns_table(fn.returns, base)}
  {overloads}
  {self.see_also(fn.see, base)}
</section>
"""

    def event_block(self, owner: str, f: Field, base: str, realm: str = "") -> str:
        anchor = field_anchor(f.name)
        full = f"{owner}.{f.name}" if owner and owner != "_G" else f.name
        return f"""
<section class="member" id="{escape(anchor)}">
  <div class="member-head">
    <h3><a class="anchor" href="#{escape(anchor)}" aria-label="Link to {escape(full)}">#</a>{escape(full)}</h3>
    <div class="member-tags">{realm_badges(f.realm or realm)}{badge(strip_generic(f.type), "b-event")}{self.source_link(f.source, f.line)}</div>
  </div>
  {render_markdown(self.site, f.description, base)}
</section>
"""

    def fields_table(self, fields: list[Field], base: str, title: str = "Fields", anchor: str = "fields",
                     realm: str = "") -> str:
        if not fields:
            return ""

        rows = []
        for f in fields:
            desc = md_inline(self.site, f.description, base)
            if f.value:
                desc += f' <span class="value">= <code>{escape(f.value)}</code></span>'
            if f.alias_of and f.alias_of != f.type:
                href = self.site.symbol_href(f.alias_of)
                code = f"<code>{escape(f.alias_of)}</code>"
                desc += f' <span class="value">alias of {f"<a class=code-link href={chr(34)}{escape(base + href)}{chr(34)}>{code}</a>" if href else code}</span>'

            name = escape(f.name) + ("?" if f.optional else "")
            rows.append(
                f'<tr id="{escape(field_anchor(f.name))}"><td><code class="p-name">{name}</code>{realm_badges(f.realm) if f.realm != realm else ""}</td>'
                f'<td><code>{render_type(self.site, f.type, base) if f.type else ""}</code></td><td>{desc}</td></tr>'
            )

        return (
            f'<h2 id="{anchor}">{escape(title)}</h2><div class="table-wrap"><table class="api"><thead><tr>'
            f"<th>Name</th><th>Type</th><th>Description</th></tr></thead><tbody>{''.join(rows)}</tbody></table></div>"
        )

    def summary_table(self, fns: list[Function], base: str, display=lambda fn: fn.full_name) -> str:
        if len(fns) < 2:
            return ""

        rows = "".join(
            f'<tr><td><a class="code-link" href="#{escape(member_anchor(fn))}"><code>{escape(display(fn))}</code></a></td>'
            f"<td>{escape(first_sentence(fn.description, 120))}</td></tr>"
            for fn in fns
        )
        return f'<div class="table-wrap"><table class="api summary"><tbody>{rows}</tbody></table></div>'

    def cards(self, names: list[str], base: str) -> str:
        cards = []
        for name in names:
            page = self.site.pages.get(name)
            if page is None:
                continue

            cards.append(
                f'<a class="card" href="{escape(base + page.href)}"><div class="card-kind k-{page.kind}">{page.kind}</div>'
                f'<div class="card-title">{escape(page.title)}</div>'
                f'<div class="card-sum">{escape(page.summary)}</div></a>'
            )

        return f'<div class="card-grid">{"".join(cards)}</div>' if cards else ""

    # -- pages ----------------------------------------------------------------

    def library_page(self, lib: LibraryInfo) -> None:
        site = self.site
        page = site.pages[lib.name]
        base = "../"
        is_globals = lib.name == "_G"
        toc: list[TocEntry] = []

        events = [f for f in lib.fields if strip_generic(f.type) in EVENT_TYPES]
        fields = [f for f in lib.fields if f not in events]

        children = sorted(
            (p.name for p in site.pages.values()
             if p.kind == "library" and p.name.rsplit(".", 1)[0] == lib.name and "." in p.name),
            key=str.lower,
        )
        nested = [n for n in lib.nested_classes if n in site.pages and site.pages[n].kind in ("class", "type")]

        sections = []
        if children:
            toc.append(TocEntry("modules", "Modules"))
            sections.append(f'<h2 id="modules">Modules</h2>{self.cards(children, base)}')

        if nested:
            toc.append(TocEntry("classes", "Classes & types"))
            sections.append(f'<h2 id="classes">Classes &amp; types</h2>{self.cards(nested, base)}')

        if fields:
            toc.append(TocEntry("fields", "Constants" if is_globals else "Fields"))
            sections.append(self.fields_table(fields, base, "Constants" if is_globals else "Fields", realm=lib.realm))

        if events:
            toc.append(TocEntry("events", "Events"))
            sections.append('<h2 id="events">Events</h2>' + "".join(self.event_block(lib.name, f, base, lib.realm) for f in events))
            for f in events:
                toc.append(TocEntry(field_anchor(f.name), f.name, 3))

        if lib.functions:
            toc.append(TocEntry("functions", "Functions"))
            sections.append(
                '<h2 id="functions">Functions</h2>'
                + self.summary_table(lib.functions, base)
                + "".join(self.function_block(fn, base) for fn in lib.functions)
            )
            for fn in lib.functions:
                toc.append(TocEntry(member_anchor(fn), fn.name, 3))

        for f in lib.fields:
            full = f.name if is_globals else f"{lib.name}.{f.name}"
            self.add_search(f.name, full, "event" if f in events else "field", f"{page.href}#{field_anchor(f.name)}", f.description)

        for fn in lib.functions:
            self.add_search(fn.name, fn.full_name, "function", f"{page.href}#{member_anchor(fn)}", fn.description)

        header_tags = [badge("globals" if is_globals else "library", "b-lib"), realm_badges(lib.realm)]
        body = f"""
{self.crumbs(page.title, base, "library") if not is_globals else self.crumbs("Globals", base, "environment")}
<h1>{escape(page.title)}</h1>
<div class="page-tags">{''.join(header_tags)}{self.source_link(lib.source, lib.line)}</div>
{render_markdown(site, lib.description, base)}
{self.see_also(lib.see, base)}
{''.join(sections) or '<p class="empty">Nothing documented here yet.</p>'}
"""
        self.write(page, page.href, page.title, body, toc)

    def inherited(self, info: ClassInfo, own: set[str], base: str) -> str:
        site = self.site
        blocks = []
        seen = set(own)
        queue = list(info.parents)
        visited: set[str] = set()
        while queue:
            parent = queue.pop(0)
            if parent in visited:
                continue

            visited.add(parent)
            parent_info = site.classes.get(parent)
            if parent_info is None:
                continue

            queue.extend(parent_info.parents)
            page = site.pages.get(parent)
            if page is None or page.kind not in ("class", "type"):
                continue

            names = []
            for fn in sorted(parent_info.methods, key=lambda f: f.name.lower()):
                if fn.visibility != "public" or fn.name in seen:
                    continue

                seen.add(fn.name)
                names.append(f'<a class="code-link" href="{escape(base + page.href)}#{escape(member_anchor(fn))}"><code>{escape(fn.name)}</code></a>')

            if names:
                blocks.append(
                    f'<details class="inherited"><summary>From <a href="{escape(base + page.href)}">{escape(parent)}</a> '
                    f'<span class="count">{len(names)}</span></summary><div class="inherited-list">{" ".join(names)}</div></details>'
                )

        if not blocks:
            return ""

        return '<h2 id="inherited">Inherited methods</h2>' + "".join(blocks)

    def ancestry(self, info: ClassInfo, base: str) -> str:
        chain: list[str] = []
        cursor: ClassInfo | None = info
        visited: set[str] = set()
        while cursor is not None and cursor.parents and cursor.name not in visited:
            visited.add(cursor.name)
            parent = cursor.parents[0]
            if parent in ("metatable", "table", "userdata"):
                break

            chain.append(parent)
            cursor = self.site.classes.get(parent)

        parts = []
        for name in reversed(chain):
            href = self.site.type_href(name)
            parts.append(f'<a href="{escape(base + href)}">{escape(name)}</a>' if href else f"<span>{escape(name)}</span>")

        extra = info.parents[1:]
        extra_html = ""
        if extra:
            extra_html = ' <span class="mixins">with ' + ", ".join(render_type(self.site, p, base) for p in extra) + "</span>"

        if not parts:
            return ""

        parts.append(f"<strong>{escape(info.name)}</strong>")
        return f'<div class="ancestry">{" → ".join(parts)}{extra_html}</div>'

    def class_page(self, info: ClassInfo) -> None:
        site = self.site
        page = site.pages[info.name]
        base = "../"
        toc: list[TocEntry] = []
        sections = []

        methods = sorted((m for m in info.methods if m.visibility == "public"), key=lambda f: f.name.lower())
        statics = sorted((s for s in info.statics if s.visibility == "public"), key=lambda f: f.name.lower())
        typing = ("__class", "__base", "__parent") if info.name not in ("Object", "Class") else ()
        all_fields = [f for f in info.fields if f.visibility == "public" and f.name.rstrip("?") not in typing]
        events = [f for f in all_fields if strip_generic(f.type) in EVENT_TYPES]
        fields = [f for f in all_fields if f not in events]

        if info.is_class and (info.overloads or info.constructor):
            ctor_name = info.constructor or base_name(info.name)
            sigs = [self.overload_sig(ctor_name, ov, base, keyword=False) for ov in info.overloads]
            if not sigs:
                sigs.append(f'<pre class="sig"><code><span class="s-name">{escape(ctor_name)}</span>(): {render_type(site, info.name, base)}</code></pre>')

            toc.append(TocEntry("constructor", "Constructor"))
            sections.append('<h2 id="constructor">Constructor</h2>' + "".join(sigs))

        if fields:
            toc.append(TocEntry("fields", "Fields"))
            sections.append(self.fields_table(fields, base, realm=info.realm))

        if info.operators:
            rows = []
            for op in info.operators:
                m = re.match(r"^(\w+)\s*(?:\((.*)\))?\s*:\s*(.+)$", op)
                if m:
                    rows.append(f"<tr><td><code>{escape(m.group(1))}</code></td><td><code>{render_type(site, m.group(2) or '', base)}</code></td><td><code>{render_type(site, m.group(3), base)}</code></td></tr>")
                else:
                    rows.append(f'<tr><td colspan="3"><code>{escape(op)}</code></td></tr>')

            toc.append(TocEntry("operators", "Operators"))
            sections.append('<h2 id="operators">Operators</h2><div class="table-wrap"><table class="api"><thead><tr><th>Operator</th><th>Operand</th><th>Result</th></tr></thead>'
                            f"<tbody>{''.join(rows)}</tbody></table></div>")

        if events:
            toc.append(TocEntry("events", "Events"))
            sections.append('<h2 id="events">Events</h2>' + "".join(self.event_block(info.name, f, base, info.realm) for f in events))

        if statics:
            toc.append(TocEntry("static", "Static functions"))
            sections.append('<h2 id="static">Static functions</h2>' + self.summary_table(statics, base, lambda fn: fn.name)
                            + "".join(self.function_block(s, base) for s in statics))
            for s in statics:
                toc.append(TocEntry(member_anchor(s), s.name, 3))

        if methods:
            toc.append(TocEntry("methods", "Methods"))
            sections.append('<h2 id="methods">Methods</h2>' + self.summary_table(methods, base, lambda fn: fn.name)
                            + "".join(self.function_block(m, base, f"{base_name(info.name)}:{m.name}") for m in methods))
            for m in methods:
                toc.append(TocEntry(member_anchor(m), m.name, 3))

        inherited = self.inherited(info, {m.name for m in methods}, base)
        if inherited:
            toc.append(TocEntry("inherited", "Inherited methods"))
            sections.append(inherited)

        subclasses = sorted(n for n in site.subclasses.get(info.name, []) if n in site.pages)
        if subclasses:
            toc.append(TocEntry("subclasses", "Subclasses"))
            links = ", ".join(f'<a href="{escape(base + site.pages[n].href)}">{escape(n)}</a>' for n in subclasses)
            sections.append(f'<h2 id="subclasses">Subclasses</h2><p class="subclasses">{links}</p>')

        kind = "class" if info.is_class else "type"
        for m in methods:
            self.add_search(m.name, f"{info.name}:{m.name}", "method", f"{page.href}#{member_anchor(m)}", m.description)
        for s in statics:
            self.add_search(s.name, s.full_name, "static", f"{page.href}#{member_anchor(s)}", s.description)
        for f in all_fields:
            self.add_search(f.name, f"{info.name}.{f.name}", "event" if f in events else "field",
                            f"{page.href}#{field_anchor(f.name)}", f.description)

        tags = [badge(kind, "b-class" if info.is_class else "b-type"), realm_badges(info.realm)]
        if info.deprecated is not None:
            tags.append(badge("deprecated", "b-warn"))

        body = f"""
{self.crumbs(info.name, base, kind)}
<h1>{escape(info.name)}</h1>
<div class="page-tags">{''.join(tags)}{self.source_link(info.source, info.line)}</div>
{self.ancestry(info, base)}
{self.deprecated_note(info.deprecated, base)}
{render_markdown(site, info.description, base)}
{self.see_also(info.see, base)}
{''.join(sections)}
"""
        self.write(page, page.href, info.name, body, toc)

    def aliases_page(self) -> None:
        site = self.site
        page = site.pages["@aliases"]
        base = ""
        blocks = []
        for alias in site.aliases.values():
            anchor = alias_anchor(alias.name)
            variants = ""
            if alias.variants:
                rows = "".join(
                    f"<tr><td><code>{render_type(site, value, base)}</code></td><td>{md_inline(site, comment, base)}</td></tr>"
                    for value, comment in alias.variants
                )
                variants = f'<div class="table-wrap"><table class="api"><thead><tr><th>Value</th><th>Description</th></tr></thead><tbody>{rows}</tbody></table></div>'

            definition = f'<pre class="sig"><code>{render_type(site, alias.definition, base)}</code></pre>' if alias.definition else ""
            blocks.append(
                f'<section class="member" id="{escape(anchor)}"><div class="member-head"><h3><a class="anchor" href="#{escape(anchor)}">#</a>{escape(alias.name)}</h3>'
                f'<div class="member-tags">{self.source_link(alias.source, alias.line)}</div></div>'
                f"{definition}{render_markdown(site, alias.description, base)}{variants}</section>"
            )
            self.add_search(alias.name, alias.name, "alias", f"aliases.html#{anchor}", alias.description)

        body = f"""
{self.crumbs("Aliases", base, "reference")}
<h1>Aliases</h1>
<div class="prose"><p>Type aliases (<code>---@alias</code>) used across the API.</p></div>
{''.join(blocks)}
"""
        self.write(page, page.href, "Aliases", body, [])

    def index_page(self) -> None:
        site = self.site
        base = ""
        top_libs = sorted((p.name for p in site.pages.values()
                           if p.kind == "library" and "." not in p.name and p.name not in INTERNAL_ROOTS), key=str.lower)
        classes = sorted((p.name for p in site.pages.values() if p.kind == "class"), key=str.lower)
        types = [p for p in site.pages.values() if p.kind == "type"]
        functions = sum(1 for e in self.search if e["k"] in ("function", "method", "static"))

        globals_card = self.cards(["_G"], base) if "_G" in site.pages else ""
        body = f"""
<div class="hero">
  <h1>dreamwork API</h1>
  <p class="lead">Reference for the dreamwork <code>std</code> environment: libraries, classes (callable tables that construct objects), data types, functions and events.</p>
  <div class="stats">
    <div><strong>{len(top_libs)}</strong><span>libraries</span></div>
    <div><strong>{len(classes)}</strong><span>classes</span></div>
    <div><strong>{len(types)}</strong><span>types</span></div>
    <div><strong>{functions}</strong><span>functions &amp; methods</span></div>
  </div>
</div>
<div class="prose">
<p>Packages run with <code>std</code> as their environment, so <code>std.print</code> is just <code>print</code> and <code>std.Queue</code> is just <code>Queue</code>.
Every entry shows the realms it is available in:
<span class="realms"><span class="realm realm-server">server</span><span class="realm realm-client">client</span><span class="realm realm-menu">menu</span></span>,
<span class="realms"><span class="realm realm-shared">shared</span></span> means both server and client.</p>
<p>Press <kbd>Ctrl</kbd> <kbd>K</kbd> or <kbd>/</kbd> to search.</p>
</div>
{globals_card}
<h2 id="libraries">Libraries</h2>
{self.cards(top_libs, base)}
<h2 id="classes">Classes</h2>
<div class="prose"><p>Classes inherit from <code>Object</code> and are created by calling the class table, e.g. <code>Queue()</code>.</p></div>
{self.cards(classes, base)}
"""
        self.write(None, "index.html", "API", body,
                   [TocEntry("libraries", "Libraries"), TocEntry("classes", "Classes")])

    def not_found_page(self, base_path: str) -> None:
        # GitHub Pages serves 404.html for a missing path at any depth, so links are site absolute
        base = base_path.rstrip("/") + "/"
        body = f"""
<h1>Page not found</h1>
<div class="prose"><p>The page does not exist, it may have been renamed. Try the search above or go back to the <a href="{escape(base)}index.html">overview</a>.</p></div>
"""
        (self.out / "404.html").write_text(self.page_shell(None, "Not found", body, [], base), encoding="utf-8")

    # -- driver ---------------------------------------------------------------

    def run(self, verbose: bool, base_path: str = "") -> None:
        if self.out.exists():
            shutil.rmtree(self.out)

        assets = self.out / "assets"
        assets.mkdir(parents=True)
        (assets / "style.css").write_text(STYLE_CSS, encoding="utf-8")
        (assets / "app.js").write_text(APP_JS, encoding="utf-8")
        (self.out / ".nojekyll").write_text("", encoding="utf-8")

        for page in self.site.pages.values():
            self.add_search(page.title, page.title if page.kind != "globals" else "_G", page.kind, page.href, page.summary)

        for name, lib in self.site.libraries.items():
            self.library_page(lib)
            if verbose:
                print(f"  library {name}")

        for name, info in self.site.classes.items():
            page = self.site.pages.get(name)
            if page is not None and page.kind in ("class", "type"):
                self.class_page(info)
                if verbose:
                    print(f"  {page.kind} {name}")

        if self.site.aliases:
            self.aliases_page()

        self.index_page()
        self.not_found_page(base_path)

        index = json.dumps(self.search, ensure_ascii=False, separators=(",", ":"))
        (assets / "search-index.js").write_text(f"window.DW_SEARCH={index};\n", encoding="utf-8")

    def check_links(self) -> list[str]:
        """Every relative link must point at a generated page and an existing anchor."""
        problems: list[str] = []
        for page_path in sorted(self.anchors):
            text = (self.out / page_path).read_text(encoding="utf-8")
            page_dir = (self.out / page_path).parent
            for href in set(re.findall(r'href="([^"]+)"', text)):
                href = html.unescape(href)
                if re.match(r"^[a-z]+:", href, re.I):
                    continue

                path, _, anchor = href.partition("#")
                target = (page_dir / path).resolve() if path else (self.out / page_path).resolve()
                try:
                    rel = target.relative_to(self.out.resolve()).as_posix()
                except ValueError:
                    problems.append(f"{page_path}: {href} leaves the site")
                    continue

                if not target.exists():
                    problems.append(f"{page_path}: missing page {href}")
                elif anchor and rel in self.anchors and anchor not in self.anchors[rel]:
                    problems.append(f"{page_path}: missing anchor {href}")

        return problems


# ---------------------------------------------------------------------------
# Assets
# ---------------------------------------------------------------------------

STYLE_CSS = r"""
:root {
  --bg: #ffffff;
  --bg-soft: #f7f8fa;
  --bg-hover: #eef0f4;
  --bg-code: #f3f4f7;
  --bg-pre: #f6f8fa;
  --border: #e3e6eb;
  --text: #1b1f24;
  --text-soft: #4b5563;
  --text-muted: #6b7280;
  --accent: #6d4aff;
  --accent-soft: rgba(109, 74, 255, 0.1);
  --link: #5b3ae6;
  --hl-k: #c2185b;
  --hl-s: #0a7e3e;
  --hl-n: #b45309;
  --hl-c: #8a94a3;
  --hl-f: #4b3fd1;
  --t-prim: #0e7490;
  --realm-server: #2563eb;
  --realm-client: #d97706;
  --realm-menu: #059669;
  --realm-shared: #7c3aed;
  --shadow: 0 1px 2px rgba(16, 24, 40, 0.05);
  --shadow-lg: 0 16px 40px rgba(16, 24, 40, 0.16);
  --topbar-h: 56px;
  --sidebar-w: 288px;
  --toc-w: 232px;
  --font: Inter, ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  --font-mono: "JetBrains Mono", ui-monospace, SFMono-Regular, Menlo, Consolas, "Liberation Mono", monospace;
  color-scheme: light;
}
[data-theme="dark"] {
  --bg: #0f1115;
  --bg-soft: #151820;
  --bg-hover: #1d212b;
  --bg-code: #1b1f28;
  --bg-pre: #161a22;
  --border: #262b36;
  --text: #e6e8ec;
  --text-soft: #b9bfca;
  --text-muted: #8b93a1;
  --accent: #9d86ff;
  --accent-soft: rgba(157, 134, 255, 0.14);
  --link: #a995ff;
  --hl-k: #ff7ab2;
  --hl-s: #7ee2a8;
  --hl-n: #fbbf6b;
  --hl-c: #6b7385;
  --hl-f: #a5b4fc;
  --t-prim: #67d4e8;
  --realm-server: #60a5fa;
  --realm-client: #fbbf24;
  --realm-menu: #34d399;
  --realm-shared: #c4b5fd;
  --shadow: none;
  --shadow-lg: 0 16px 40px rgba(0, 0, 0, 0.5);
  color-scheme: dark;
}

* { box-sizing: border-box; }
html { scroll-padding-top: calc(var(--topbar-h) + 16px); }
body {
  margin: 0;
  font-family: var(--font);
  font-size: 15px;
  line-height: 1.65;
  color: var(--text);
  background: var(--bg);
  -webkit-font-smoothing: antialiased;
}
a { color: var(--link); text-decoration: none; }
a:hover { text-decoration: underline; }
code, kbd, pre { font-family: var(--font-mono); }
kbd {
  font-size: 0.75em;
  padding: 0.1em 0.4em;
  border: 1px solid var(--border);
  border-bottom-width: 2px;
  border-radius: 4px;
  background: var(--bg-soft);
}

/* top bar */
.topbar {
  position: sticky;
  top: 0;
  z-index: 40;
  height: var(--topbar-h);
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 0 1.25rem;
  background: color-mix(in srgb, var(--bg) 88%, transparent);
  backdrop-filter: saturate(1.4) blur(10px);
  border-bottom: 1px solid var(--border);
}
.brand {
  font-weight: 700;
  font-size: 1.1rem;
  letter-spacing: -0.02em;
  color: var(--text);
  white-space: nowrap;
  min-width: calc(var(--sidebar-w) - 2.25rem);
}
.brand:hover { text-decoration: none; }
.brand span { color: var(--accent); }
.brand small {
  margin-left: 0.5rem;
  font-size: 0.68rem;
  font-weight: 600;
  padding: 0.12rem 0.45rem;
  border-radius: 999px;
  background: var(--accent-soft);
  color: var(--accent);
  vertical-align: middle;
}
.search-wrap { position: relative; flex: 1; max-width: 560px; }
.search-wrap input {
  width: 100%;
  height: 36px;
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 0 4.5rem 0 0.85rem;
  font: inherit;
  font-size: 0.9rem;
  color: var(--text);
  background: var(--bg-soft);
}
.search-wrap input:focus { outline: 2px solid var(--accent-soft); border-color: var(--accent); background: var(--bg); }
.search-kbd { position: absolute; right: 0.6rem; top: 50%; transform: translateY(-50%); color: var(--text-muted); pointer-events: none; }
.search-results {
  display: none;
  position: absolute;
  left: 0; right: 0;
  top: calc(100% + 6px);
  max-height: min(70vh, 560px);
  overflow: auto;
  background: var(--bg);
  border: 1px solid var(--border);
  border-radius: 10px;
  box-shadow: var(--shadow-lg);
  padding: 0.35rem;
}
.search-results.open { display: block; }
.search-hit { display: block; padding: 0.5rem 0.65rem; border-radius: 7px; color: inherit; }
.search-hit:hover, .search-hit.sel { background: var(--accent-soft); text-decoration: none; }
.search-hit .hit-top { display: flex; align-items: baseline; gap: 0.5rem; }
.search-hit .hit-kind { font-size: 0.66rem; text-transform: uppercase; letter-spacing: 0.05em; color: var(--text-muted); min-width: 4.2rem; }
.search-hit .hit-name { font-family: var(--font-mono); font-size: 0.85rem; font-weight: 600; }
.search-hit .hit-name mark { background: none; color: var(--accent); }
.search-hit .hit-sum { font-size: 0.8rem; color: var(--text-muted); margin-left: 4.7rem; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.search-empty { padding: 0.75rem; color: var(--text-muted); font-size: 0.85rem; }
.top-actions { margin-left: auto; display: flex; align-items: center; gap: 0.5rem; }
.top-link { font-size: 0.88rem; color: var(--text-soft); font-weight: 500; }
.theme-toggle, .menu-toggle {
  width: 34px; height: 34px;
  border: 1px solid var(--border);
  border-radius: 8px;
  background: var(--bg);
  color: var(--text-soft);
  cursor: pointer;
  font-size: 1rem;
}
.theme-toggle::before { content: "☾"; }
[data-theme="dark"] .theme-toggle::before { content: "☀"; }
.menu-toggle { display: none; }

/* layout */
.layout { display: flex; align-items: flex-start; max-width: 1480px; margin: 0 auto; }
.sidebar {
  position: sticky;
  top: var(--topbar-h);
  width: var(--sidebar-w);
  flex: 0 0 var(--sidebar-w);
  height: calc(100vh - var(--topbar-h));
  overflow-y: auto;
  padding: 1rem 0.75rem 3rem;
  border-right: 1px solid var(--border);
  scrollbar-width: thin;
}
.content { flex: 1; min-width: 0; padding: 2rem 3rem 4rem; }
.page { max-width: 820px; }
.toc {
  position: sticky;
  top: var(--topbar-h);
  width: var(--toc-w);
  flex: 0 0 var(--toc-w);
  max-height: calc(100vh - var(--topbar-h));
  overflow-y: auto;
  padding: 2rem 1rem 2rem 0.5rem;
  font-size: 0.82rem;
  scrollbar-width: thin;
}
.toc-title { font-weight: 600; font-size: 0.72rem; text-transform: uppercase; letter-spacing: 0.06em; color: var(--text-muted); margin-bottom: 0.5rem; }
.toc ul { list-style: none; margin: 0; padding: 0; border-left: 1px solid var(--border); }
.toc li a { display: block; padding: 0.18rem 0 0.18rem 0.75rem; margin-left: -1px; border-left: 2px solid transparent; color: var(--text-muted); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.toc li.toc-l3 a { padding-left: 1.5rem; font-family: var(--font-mono); font-size: 0.78rem; }
.toc li a:hover { color: var(--text); text-decoration: none; }
.toc li a.current { color: var(--accent); border-left-color: var(--accent); }

/* navigation */
.nav-group { margin-bottom: 1rem; }
.nav-title { font-size: 0.7rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.07em; color: var(--text-muted); padding: 0.35rem 0.5rem; }
.nav-tree { list-style: none; margin: 0; padding: 0; }
.nav-tree .nav-tree { margin-left: 0.75rem; padding-left: 0.3rem; border-left: 1px solid var(--border); }
.nav-item:not(.open) > .nav-tree { display: none; }
.nav-row { display: flex; align-items: center; border-radius: 6px; }
.nav-row > a, .nav-row > .nav-label {
  flex: 1;
  min-width: 0;
  display: flex;
  align-items: center;
  gap: 0.4rem;
  padding: 0.22rem 0.4rem;
  border-radius: 6px;
  color: var(--text-soft);
  font-size: 0.88rem;
  white-space: nowrap;
  overflow: hidden;
}
.nav-row > a span:last-child, .nav-row > .nav-label span:last-child { overflow: hidden; text-overflow: ellipsis; }
.nav-row > a:hover { background: var(--bg-hover); color: var(--text); text-decoration: none; }
.nav-row > a.active { background: var(--accent-soft); color: var(--accent); font-weight: 600; }
.nav-twist, .nav-twist-pad { flex: 0 0 18px; width: 18px; height: 22px; }
.nav-twist { border: 0; background: none; padding: 0; color: var(--text-muted); cursor: pointer; border-radius: 4px; }
.nav-twist::before { content: ""; display: inline-block; width: 6px; height: 6px; border-right: 1.5px solid currentColor; border-bottom: 1.5px solid currentColor; transform: rotate(-45deg); transition: transform 0.15s; }
.nav-item.open > .nav-row > .nav-twist::before { transform: rotate(45deg); }
.nav-twist:hover { color: var(--text); background: var(--bg-hover); }
.nav-icon { flex: 0 0 auto; font-size: 0.6rem; font-weight: 700; width: 15px; height: 15px; line-height: 15px; text-align: center; border-radius: 4px; font-family: var(--font-mono); }
.nav-class { background: rgba(37, 99, 235, 0.14); color: var(--realm-server); }
.nav-type { background: rgba(5, 150, 105, 0.14); color: var(--realm-menu); }

/* page */
.crumbs { font-size: 0.82rem; color: var(--text-muted); margin-bottom: 0.75rem; display: flex; flex-wrap: wrap; gap: 0.3rem; align-items: center; }
.crumbs a { color: var(--text-muted); }
.crumb-kind { font-size: 0.66rem; text-transform: uppercase; letter-spacing: 0.06em; font-weight: 600; color: var(--accent); margin-right: 0.4rem; }
h1 { font-size: 2.1rem; line-height: 1.2; letter-spacing: -0.025em; margin: 0 0 0.6rem; font-weight: 700; word-break: break-word; }
h2 { font-size: 1.4rem; letter-spacing: -0.015em; margin: 2.6rem 0 0.9rem; padding-bottom: 0.4rem; border-bottom: 1px solid var(--border); font-weight: 650; }
h3 { font-size: 1.05rem; margin: 0; font-family: var(--font-mono); font-weight: 600; word-break: break-word; }
.page-tags { display: flex; flex-wrap: wrap; gap: 0.4rem; align-items: center; margin-bottom: 1rem; }
.badge { display: inline-block; font-size: 0.7rem; font-weight: 600; padding: 0.1rem 0.5rem; border-radius: 999px; background: var(--bg-code); color: var(--text-muted); border: 1px solid var(--border); line-height: 1.5; }
.b-lib { color: var(--accent); background: var(--accent-soft); border-color: transparent; }
.b-class { color: var(--realm-server); background: rgba(37, 99, 235, 0.1); border-color: transparent; }
.b-type { color: var(--realm-menu); background: rgba(5, 150, 105, 0.1); border-color: transparent; }
.b-event { color: var(--realm-client); }
.b-async { color: var(--realm-shared); }
.b-warn { color: #b91c1c; background: rgba(220, 38, 38, 0.1); border-color: transparent; }
.realms { display: inline-flex; border-radius: 6px; overflow: hidden; border: 1px solid var(--border); vertical-align: middle; }
.realm { font-size: 0.66rem; font-weight: 700; letter-spacing: 0.04em; text-transform: uppercase; padding: 0.08rem 0.42rem; line-height: 1.55; }
.realm + .realm { border-left: 1px solid var(--border); }
.realm-server { color: var(--realm-server); }
.realm-client { color: var(--realm-client); }
.realm-menu { color: var(--realm-menu); }
.realm-shared { color: var(--realm-shared); }
td .realms { margin-left: 0.4rem; }
.src-link { font-size: 0.75rem; color: var(--text-muted); margin-left: 0.25rem; }
.ancestry { font-family: var(--font-mono); font-size: 0.85rem; color: var(--text-muted); margin: 0 0 1rem; }
.ancestry strong { color: var(--text); }
.mixins { font-size: 0.82rem; }
.lead { font-size: 1.1rem; color: var(--text-soft); }
.hero { margin-bottom: 1.5rem; }
.stats { display: flex; flex-wrap: wrap; gap: 0.75rem; margin: 1.25rem 0 0.5rem; }
.stats div { flex: 1 1 120px; border: 1px solid var(--border); border-radius: 10px; padding: 0.75rem 1rem; background: var(--bg-soft); }
.stats strong { display: block; font-size: 1.5rem; letter-spacing: -0.02em; }
.stats span { color: var(--text-muted); font-size: 0.82rem; }
.empty { color: var(--text-muted); }

/* prose */
.prose { color: var(--text); }
.prose p { margin: 0.6rem 0; }
.prose h3, .prose h4, .prose h5, .prose h6 { font-family: var(--font); margin: 1.3rem 0 0.5rem; font-size: 1rem; }
.prose ul, .prose ol, ul.see { margin: 0.5rem 0 0.8rem; padding-left: 1.4rem; }
.prose li { margin: 0.2rem 0; }
.prose hr { border: 0; border-top: 1px solid var(--border); margin: 1.2rem 0; }
.prose a { text-decoration: underline; text-decoration-color: color-mix(in srgb, var(--link) 40%, transparent); text-underline-offset: 2px; }
.prose a.code-link { text-decoration: none; }
:not(pre) > code, .code-link code {
  font-size: 0.86em;
  background: var(--bg-code);
  border: 1px solid var(--border);
  padding: 0.05em 0.35em;
  border-radius: 5px;
  overflow-wrap: break-word;
}
.code-link code { color: var(--link); }
.code-link:hover { text-decoration: none; }
.code-link:hover code { border-color: var(--accent); }
.hint { margin: 1rem 0; padding: 0.6rem 1rem; border-radius: 8px; border: 1px solid var(--border); border-left: 4px solid var(--accent); background: var(--bg-soft); }
.hint p { margin: 0.3rem 0; }
.hint-warning, .hint-caution { border-left-color: #d97706; }
.hint-important { border-left-color: #dc2626; }
.hint-tip { border-left-color: #059669; }

.code-block { margin: 0.9rem 0; border: 1px solid var(--border); border-radius: 10px; overflow: hidden; background: var(--bg-pre); }
.code-head { display: flex; justify-content: space-between; align-items: center; padding: 0.3rem 0.5rem 0.3rem 0.9rem; border-bottom: 1px solid var(--border); font-size: 0.7rem; text-transform: uppercase; letter-spacing: 0.05em; color: var(--text-muted); }
.copy-btn { font: inherit; font-size: 0.7rem; text-transform: none; letter-spacing: 0; border: 1px solid var(--border); background: var(--bg); color: var(--text-soft); border-radius: 5px; padding: 0.1rem 0.5rem; cursor: pointer; }
.code-block pre { margin: 0; padding: 0.85rem 1rem; overflow-x: auto; font-size: 0.84rem; line-height: 1.55; }
.hl-k { color: var(--hl-k); }
.hl-s, .t-str { color: var(--hl-s); }
.hl-n { color: var(--hl-n); }
.hl-c { color: var(--hl-c); font-style: italic; }
.hl-f { color: var(--hl-f); }
.t-prim { color: var(--t-prim); }
.t-link { color: var(--link); }

/* api blocks */
.sig { margin: 0.6rem 0; padding: 0.7rem 0.95rem; background: var(--bg-pre); border: 1px solid var(--border); border-radius: 8px; overflow-x: auto; font-size: 0.85rem; line-height: 1.55; white-space: pre-wrap; word-break: break-word; }
.sig .s-name { font-weight: 600; }
.sig .s-param { color: var(--text-soft); }
.member { padding: 1.4rem 0 1.1rem; border-bottom: 1px solid var(--border); }
.member:last-child { border-bottom: 0; }
.member-head { display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: 0.5rem; }
.member-tags { display: flex; flex-wrap: wrap; gap: 0.35rem; align-items: center; }
.member h3 { position: relative; }
.anchor { position: absolute; right: 100%; padding-right: 0.35em; color: var(--text-muted); opacity: 0; font-weight: 400; }
.member h3:hover .anchor, .anchor:focus { opacity: 1; text-decoration: none; }
.member:target { animation: flash 1.6s ease-out; }
@keyframes flash { from { background: var(--accent-soft); } to { background: transparent; } }
.sub-title { font-size: 0.72rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.06em; color: var(--text-muted); margin: 1rem 0 0.35rem; }
.alias-note { color: var(--text-muted); font-size: 0.9rem; }
.value { color: var(--text-muted); font-size: 0.85rem; white-space: nowrap; }
.opt { margin-left: 0.4rem; font-size: 0.68rem; color: var(--text-muted); font-style: italic; }

.table-wrap { overflow-x: auto; margin: 0.4rem 0 1rem; }
table { width: 100%; border-collapse: collapse; font-size: 0.88rem; }
.prose table th, .prose table td, table.api th, table.api td { text-align: left; padding: 0.5rem 0.7rem; border-bottom: 1px solid var(--border); vertical-align: top; }
table.api thead th, .prose table th { font-size: 0.7rem; text-transform: uppercase; letter-spacing: 0.05em; color: var(--text-muted); font-weight: 600; background: var(--bg-soft); }
table.api td:first-child { white-space: nowrap; }
table.api td:nth-child(2) { min-width: 6.5rem; }
table.api tr:target { background: var(--accent-soft); }
table.summary td:first-child { width: 1%; }
table.summary td { padding: 0.4rem 0.7rem; }

.card-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(230px, 1fr)); gap: 0.75rem; margin: 0.75rem 0 1.5rem; }
.card { display: block; border: 1px solid var(--border); border-radius: 10px; padding: 0.8rem 1rem; color: inherit; background: var(--bg); box-shadow: var(--shadow); transition: border-color 0.12s, transform 0.12s; }
.card:hover { border-color: var(--accent); text-decoration: none; transform: translateY(-1px); }
.card-kind { font-size: 0.64rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.06em; color: var(--text-muted); }
.k-library, .k-globals { color: var(--accent); }
.k-class { color: var(--realm-server); }
.k-type { color: var(--realm-menu); }
.card-title { font-family: var(--font-mono); font-weight: 600; margin: 0.15rem 0 0.25rem; word-break: break-word; }
.card-sum { font-size: 0.82rem; color: var(--text-muted); display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }

details.inherited { border: 1px solid var(--border); border-radius: 8px; margin: 0.5rem 0; background: var(--bg-soft); }
details.inherited summary { cursor: pointer; padding: 0.5rem 0.85rem; font-size: 0.9rem; }
details.inherited .count { font-size: 0.72rem; color: var(--text-muted); margin-left: 0.3rem; }
.inherited-list { padding: 0 0.85rem 0.7rem; display: flex; flex-wrap: wrap; gap: 0.35rem; }
.subclasses { font-family: var(--font-mono); font-size: 0.88rem; line-height: 1.9; }

.pager { display: flex; justify-content: space-between; gap: 1rem; max-width: 820px; margin-top: 3rem; }
.pager a { flex: 1; max-width: 50%; border: 1px solid var(--border); border-radius: 10px; padding: 0.75rem 1rem; color: var(--text); font-weight: 600; font-family: var(--font-mono); font-size: 0.9rem; word-break: break-word; }
.pager a span { display: block; font-family: var(--font); font-weight: 400; font-size: 0.75rem; color: var(--text-muted); }
.pager a:hover { border-color: var(--accent); text-decoration: none; }
.pager-next { text-align: right; margin-left: auto; }
.page-foot { max-width: 820px; margin-top: 2.5rem; padding-top: 1rem; border-top: 1px solid var(--border); font-size: 0.8rem; color: var(--text-muted); }

@media (max-width: 1240px) { .toc { display: none; } }
@media (max-width: 900px) {
  .menu-toggle { display: inline-block; }
  .brand { min-width: 0; }
  .search-kbd, .top-link { display: none; }
  .sidebar { position: fixed; left: 0; top: var(--topbar-h); z-index: 30; background: var(--bg); transform: translateX(-105%); transition: transform 0.2s ease; box-shadow: var(--shadow-lg); }
  .sidebar.open { transform: none; }
  .content { padding: 1.25rem 1.1rem 3rem; }
  h1 { font-size: 1.7rem; }
}
"""

APP_JS = r"""
(function () {
  "use strict";
  var base = document.body.getAttribute("data-base") || "";
  var root = document.documentElement;

  // theme
  var themeBtn = document.getElementById("theme-toggle");
  if (themeBtn) themeBtn.addEventListener("click", function () {
    var next = root.dataset.theme === "dark" ? "light" : "dark";
    root.dataset.theme = next;
    try { localStorage.setItem("dw-theme", next); } catch (e) {}
  });

  // navigation tree
  var sidebar = document.getElementById("sidebar");
  document.querySelectorAll(".nav-twist").forEach(function (btn) {
    btn.addEventListener("click", function () {
      var item = btn.closest(".nav-item");
      var open = item.classList.toggle("open");
      btn.setAttribute("aria-expanded", open ? "true" : "false");
    });
  });
  var toggle = document.getElementById("menu-toggle");
  if (toggle && sidebar) toggle.addEventListener("click", function () { sidebar.classList.toggle("open"); });
  if (sidebar) {
    var key = "dw-nav-scroll";
    var active = sidebar.querySelector("a.active");
    var saved = null;
    try { saved = sessionStorage.getItem(key); } catch (e) {}
    if (saved !== null) sidebar.scrollTop = +saved;
    if (active) {
      var r = active.getBoundingClientRect(), s = sidebar.getBoundingClientRect();
      if (r.top < s.top || r.bottom > s.bottom) active.scrollIntoView({ block: "center" });
    }
    window.addEventListener("beforeunload", function () {
      try { sessionStorage.setItem(key, sidebar.scrollTop); } catch (e) {}
    });
  }

  // copy buttons
  document.querySelectorAll(".copy-btn").forEach(function (btn) {
    btn.addEventListener("click", function () {
      var code = btn.closest(".code-block").querySelector("code").innerText;
      var done = function () { btn.textContent = "Copied"; setTimeout(function () { btn.textContent = "Copy"; }, 1200); };
      if (navigator.clipboard) navigator.clipboard.writeText(code).then(done, function () {});
    });
  });

  // table of contents scroll spy
  var tocLinks = Array.prototype.slice.call(document.querySelectorAll(".toc a"));
  if (tocLinks.length && "IntersectionObserver" in window) {
    var byId = {};
    tocLinks.forEach(function (a) { byId[decodeURIComponent(a.getAttribute("href").slice(1))] = a; });
    var visible = {};
    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) { visible[e.target.id] = e.isIntersecting; });
      var first = null;
      for (var i = 0; i < tocLinks.length; i++) {
        var id = decodeURIComponent(tocLinks[i].getAttribute("href").slice(1));
        if (visible[id]) { first = tocLinks[i]; break; }
      }
      if (first) {
        tocLinks.forEach(function (a) { a.classList.toggle("current", a === first); });
      }
    }, { rootMargin: "-56px 0px -60% 0px" });
    Object.keys(byId).forEach(function (id) {
      var el = document.getElementById(id);
      if (el) observer.observe(el);
    });
  }

  // search
  var input = document.getElementById("doc-search");
  var results = document.getElementById("search-results");
  if (!input || !results) return;

  var index = null, loading = false, hits = [], selected = 0;
  function load() {
    if (index || loading) return;
    loading = true;
    var s = document.createElement("script");
    s.src = base + "assets/search-index.js";
    s.onload = function () { index = window.DW_SEARCH || []; render(); };
    document.head.appendChild(s);
  }
  input.addEventListener("focus", load);

  function score(item, q) {
    var name = item.n.toLowerCase(), full = item.f.toLowerCase();
    var s = 0;
    if (name === q || full === q) s = 100;
    else if (name.indexOf(q) === 0) s = 80;
    else if (full.indexOf(q) === 0) s = 72;
    else if (name.indexOf(q) > 0) s = 50;
    else if (full.indexOf(q) > 0) s = 45;
    else if (item.s && item.s.toLowerCase().indexOf(q) >= 0) s = 15;
    else return 0;
    if (item.k === "library" || item.k === "class" || item.k === "globals") s += 6;
    return s - Math.min(full.length, 60) / 30;
  }
  function esc(s) {
    return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
  }
  function mark(text, q) {
    var i = text.toLowerCase().indexOf(q);
    if (i < 0 || !q) return esc(text);
    return esc(text.slice(0, i)) + "<mark>" + esc(text.slice(i, i + q.length)) + "</mark>" + esc(text.slice(i + q.length));
  }
  function render() {
    var q = input.value.trim().toLowerCase();
    if (!q) { results.classList.remove("open"); results.innerHTML = ""; return; }
    if (!index) { load(); return; }
    var terms = q.split(/\s+/);
    hits = index.map(function (item) {
      var total = 0;
      for (var i = 0; i < terms.length; i++) {
        var s = score(item, terms[i]);
        if (!s) return null;
        total += s;
      }
      return { item: item, s: total };
    }).filter(Boolean).sort(function (a, b) {
      return b.s - a.s || a.item.f.localeCompare(b.item.f);
    }).slice(0, 50);
    selected = 0;
    if (!hits.length) {
      results.innerHTML = '<div class="search-empty">No results for “' + esc(q) + '”</div>';
    } else {
      results.innerHTML = hits.map(function (h, i) {
        var it = h.item;
        return '<a class="search-hit' + (i === 0 ? " sel" : "") + '" role="option" href="' + esc(base + it.h) + '">' +
          '<div class="hit-top"><span class="hit-kind">' + esc(it.k) + '</span><span class="hit-name">' + mark(it.f, terms[0]) + "</span></div>" +
          (it.s ? '<div class="hit-sum">' + esc(it.s) + "</div>" : "") + "</a>";
      }).join("");
    }
    results.classList.add("open");
  }
  function select(i) {
    var nodes = results.querySelectorAll(".search-hit");
    if (!nodes.length) return;
    selected = (i + nodes.length) % nodes.length;
    nodes.forEach(function (n, k) { n.classList.toggle("sel", k === selected); });
    nodes[selected].scrollIntoView({ block: "nearest" });
  }

  var timer = null;
  input.addEventListener("input", function () { clearTimeout(timer); timer = setTimeout(render, 60); });
  input.addEventListener("keydown", function (e) {
    if (e.key === "ArrowDown") { e.preventDefault(); select(selected + 1); }
    else if (e.key === "ArrowUp") { e.preventDefault(); select(selected - 1); }
    else if (e.key === "Enter") {
      var node = results.querySelectorAll(".search-hit")[selected];
      if (node) { e.preventDefault(); location.href = node.href; }
    } else if (e.key === "Escape") { results.classList.remove("open"); input.blur(); }
  });
  document.addEventListener("keydown", function (e) {
    var typing = /^(INPUT|TEXTAREA|SELECT)$/.test(document.activeElement.tagName);
    if ((e.key === "k" && (e.ctrlKey || e.metaKey)) || (e.key === "/" && !typing)) {
      e.preventDefault();
      input.focus();
      input.select();
    }
  });
  document.addEventListener("click", function (e) {
    if (!results.contains(e.target) && e.target !== input) results.classList.remove("open");
  });

  // `?q=term` opens the search with the term
  var initial = new URLSearchParams(location.search).get("q");
  if (initial) {
    input.value = initial;
    input.focus();
    load();
  }
})();
"""


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def collect(meta_root: Path) -> tuple[dict[str, ClassInfo], dict[str, LibraryInfo], list[AliasInfo]]:
    library = meta_root / "library"
    if not library.is_dir():
        raise SystemExit(f"missing library directory: {library}")

    all_classes: dict[str, ClassInfo] = {}
    all_aliases: dict[str, AliasInfo] = {}
    all_functions: list[Function] = []
    all_values: list[ValueDef] = []
    all_assignments: dict[str, int] = {}

    for path in sorted(library.rglob("*.lua")):
        parsed = parse_file(path, library)
        for name, info in parsed.classes.items():
            existing = all_classes.get(name)
            if existing is None:
                all_classes[name] = info
                continue

            if info.declared and not existing.declared:
                existing.source, existing.line, existing.declared = info.source, info.line, True

            existing.description = existing.description or info.description
            existing.realm = existing.realm or info.realm
            existing.parents = existing.parents or info.parents
            existing.fields.extend(info.fields)
            merge_functions(existing.methods, info.methods)
            merge_functions(existing.statics, info.statics)
            existing.overloads.extend(info.overloads)
            existing.operators.extend(info.operators)
            existing.see.extend(info.see)

        for alias in parsed.aliases:
            known = all_aliases.get(alias.name)
            if known is None or (not known.description and alias.description):
                all_aliases[alias.name] = alias

        all_functions.extend(parsed.functions)
        all_values.extend(parsed.values)
        all_assignments.update(parsed.assignments)

    functions_by_name = {f.full_name: f for f in all_functions}
    global_fields: list[Field] = []
    global_fns: list[Function] = []
    attach_values(all_values, all_classes, functions_by_name, global_fields, global_fns)

    classify(all_classes, all_assignments)

    # fields declared by both `---@field` and `---@type` stubs collapse into one
    for info in all_classes.values():
        merged: dict[str, Field] = {}
        for f in info.fields:
            key = f.name.rstrip("?")
            known = merged.setdefault(key, f)
            if known is f:
                continue

            known.description = known.description or f.description
            known.realm = known.realm or f.realm
            known.value = known.value or f.value
            if known.type in ("", "table") and f.type:
                known.type = f.type

        info.fields = list(merged.values())
    libraries = build_libraries(all_classes, all_functions + global_fns, global_fields)
    return all_classes, libraries, list(all_aliases.values())


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--input", required=True, type=Path, help="meta branch root (contains library/)")
    parser.add_argument("--output", required=True, type=Path, help="directory for the static site")
    parser.add_argument("--repo-url", default="", help="repository URL for source links, e.g. https://github.com/owner/repo")
    parser.add_argument("--source-ref", default="meta", help="branch of the meta files for source links")
    parser.add_argument("--base-path", default="", help="URL path the site is served from, e.g. /repo (for 404.html)")
    parser.add_argument("--strict", action="store_true", help="fail on broken internal links")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    classes, libraries, aliases = collect(args.input)
    site = Site(libraries, classes, aliases, args.repo_url, args.source_ref)
    renderer = Renderer(site, args.output)
    renderer.run(args.verbose, args.base_path)

    kinds = defaultdict(int)
    for page in site.pages.values():
        kinds[page.kind] += 1

    print(
        f"docs: {kinds['library']} libraries, {kinds['class']} classes, {kinds['type']} types, "
        f"{len(site.aliases)} aliases, {len(renderer.search)} search entries -> {args.output}"
    )

    problems = renderer.check_links()
    for problem in problems[:50]:
        print(("::error::" if args.strict else "::warning::") + problem)

    if len(problems) > 50:
        print(f"... and {len(problems) - 50} more broken links")

    return 1 if problems and args.strict else 0


if __name__ == "__main__":
    sys.exit(main())

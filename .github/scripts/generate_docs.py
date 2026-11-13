#!/usr/bin/env python3
"""
Builds a GitBook-style static site from LuaLS meta definitions.

Parses EmmyLua annotations under a meta `library/` tree (the generated `meta`
branch) and emits HTML pages for libraries, classes, functions and methods,
plus a client-side search index.

Classes are tables that construct objects: a companion `*Class` with
`---@overload fun(...): T` / `---@operator call: T`, usually with the instance
type inheriting `: Object`.

Usage: generate_docs.py --input <meta root> --output <docs dir> [--verbose]
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
from typing import Any


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
    visibility: str = "public"  # public | protected | private
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
    visibility: str = "public"
    nodiscard: bool = False
    async_: bool = False
    source: str = ""
    line: int = 0
    signature: str = ""


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
    aliases_attached: list[str] = field(default_factory=list)
    source: str = ""
    line: int = 0
    is_class: bool = False  # constructible Object class
    is_library: bool = False
    instance_of: str = ""  # if this is a *Class companion, the instance type
    class_of: str = ""  # companion Class type name
    constructor: str = ""  # pretty ctor signature


@dataclass
class AliasInfo:
    name: str
    definition: str = ""
    description: str = ""
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
    source: str = ""
    line: int = 0


@dataclass
class DocBlock:
    description: str = ""
    realm: str = ""
    tags: list[tuple[str, str]] = field(default_factory=list)
    start_line: int = 0


# ---------------------------------------------------------------------------
# Parsing
# ---------------------------------------------------------------------------

REALM_RE = re.compile(r"^\[([A-Z /]+)\]\s*$")

FN_RE = re.compile(
    r"^((?:local\s+)?)function\s+"
    r"([A-Za-z_][\w.]*)"
    r"([.:])"
    r"([A-Za-z_]\w*)"
    r"\s*\(([^)]*)\)"
)
FN_GLOBAL_RE = re.compile(
    r"^((?:local\s+)?)function\s+"
    r"([A-Za-z_]\w*)"
    r"\s*\(([^)]*)\)"
)
ASSIGN_TABLE_RE = re.compile(r"^([A-Za-z_][\w.]*)\s*=\s*\{\}")
LOCAL_TABLE_RE = re.compile(r"^local\s+([A-Za-z_]\w*)\s*=\s*\{\}")

GENERIC_STRIP = re.compile(r"<[^>]*>")


def strip_generic(name: str) -> str:
    return GENERIC_STRIP.sub("", name).strip()


def base_name(name: str) -> str:
    return strip_generic(name).split(".")[-1]


def escape(text: str) -> str:
    return html.escape(text, quote=True)


def normalize_ws(text: str) -> str:
    return re.sub(r"[ \t]+\n", "\n", text).strip()


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
        realm = ""
        saw_blank = False

        while i < n and lines[i].startswith("---"):
            raw = lines[i][3:]
            if raw.startswith(" "):
                raw = raw[1:]
            elif raw.startswith("\t"):
                raw = raw[1:]

            if raw.startswith("@"):
                space = raw.find(" ")
                if space == -1:
                    tags.append((raw[1:], ""))
                else:
                    tags.append((raw[1:space], raw[space + 1 :].strip()))
            else:
                realm_match = REALM_RE.match(raw.strip())
                if realm_match and not desc_lines and not tags:
                    realm = realm_match.group(1).strip()
                elif raw.strip() == "":
                    if desc_lines:
                        saw_blank = True
                        desc_lines.append("")
                else:
                    if tags:
                        # stray prose after tags — treat as description continuation
                        desc_lines.append(raw)
                    else:
                        desc_lines.append(raw)
            i += 1

        description = normalize_ws("\n".join(desc_lines))
        if saw_blank:
            description = re.sub(r"\n{3,}", "\n\n", description)

        blocks.append(
            (
                start,
                i,
                DocBlock(
                    description=description,
                    realm=realm,
                    tags=tags,
                    start_line=start + 1,
                ),
            )
        )

    return blocks


def tag_map(block: DocBlock) -> dict[str, list[str]]:
    out: dict[str, list[str]] = defaultdict(list)
    for name, value in block.tags:
        out[name].append(value)
    return out


def visibility_from_tags(tags: dict[str, list[str]]) -> str:
    if "private" in tags:
        return "private"
    if "protected" in tags:
        return "protected"
    return "public"


def parse_params(tags: dict[str, list[str]]) -> list[Param]:
    params: list[Param] = []
    for value in tags.get("param", []):
        parts = value.split(None, 2)
        if len(parts) < 2:
            continue
        name, typ = parts[0], parts[1]
        desc = parts[2] if len(parts) > 2 else ""
        optional = name.endswith("?") or typ.endswith("?")
        params.append(
            Param(
                name=name.rstrip("?"),
                type=typ,
                description=desc,
                optional=optional,
            )
        )
    return params


def parse_returns(tags: dict[str, list[str]]) -> list[Return]:
    returns: list[Return] = []
    for value in tags.get("return", []):
        parts = value.split(None, 2)
        if not parts:
            continue
        typ = parts[0]
        name = ""
        desc = ""
        if len(parts) == 2:
            if re.match(r"^[A-Za-z_][\w]*$", parts[1]):
                name = parts[1]
            else:
                desc = parts[1]
        elif len(parts) >= 3:
            name, desc = parts[1], parts[2]
        returns.append(Return(type=typ, name=name, description=desc))
    return returns


def parse_fields(tags: dict[str, list[str]], source: str, line: int) -> list[Field]:
    fields: list[Field] = []
    for value in tags.get("field", []):
        match = re.match(
            r"^(?:(public|protected|private)\s+)?(\S+)\s+(\S+)\s*(.*)$",
            value,
        )
        if not match:
            continue
        vis, name, typ, desc = match.groups()
        fields.append(
            Field(
                name=name,
                type=typ,
                description=desc or "",
                visibility=vis or "public",
                source=source,
                line=line,
            )
        )
    return fields


def preceding_block(
    blocks_by_end: dict[int, DocBlock], lines: list[str], line_idx: int
) -> DocBlock | None:
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
    assignments: dict[str, int] = field(default_factory=dict)  # name -> line
    local_aliases: dict[str, str] = field(default_factory=dict)  # local stub -> class


def parse_file(path: Path, root: Path) -> ParsedFile:
    rel = str(path.relative_to(root)).replace("\\", "/")
    text = path.read_text(encoding="utf-8", errors="replace")
    lines = text.splitlines()
    blocks = parse_doc_blocks(lines)
    blocks_by_end = {end: block for _, end, block in blocks}

    parsed = ParsedFile(path=rel)

    # First pass: class / alias annotations (attached to following lines or standalone)
    for start, end, block in blocks:
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
                    source=rel,
                    line=block.start_line,
                )
            )

        for value in tags.get("class", []):
            match = re.match(r"^(.+?)(?:\s*:\s*(.+))?$", value)
            if not match:
                continue
            raw_name = match.group(1).strip()
            parents_raw = match.group(2) or ""
            name = strip_generic(raw_name)
            parents = [strip_generic(p.strip()) for p in parents_raw.split(",") if p.strip()]

            info = parsed.classes.get(name) or ClassInfo(name=name, source=rel, line=block.start_line)
            if not info.description:
                info.description = block.description
            if not info.realm:
                info.realm = block.realm
            if parents and not info.parents:
                info.parents = parents
            info.fields.extend(parse_fields(tags, rel, block.start_line))
            info.overloads.extend(tags.get("overload", []))
            info.operators.extend(tags.get("operator", []))
            parsed.classes[name] = info

            # bind following local/global assignment name for methods
            for k in range(end, min(end + 5, len(lines))):
                local_m = LOCAL_TABLE_RE.match(lines[k].strip())
                assign_m = ASSIGN_TABLE_RE.match(lines[k].strip())
                if local_m:
                    parsed.local_aliases[local_m.group(1)] = name
                    break
                if assign_m:
                    parsed.assignments[assign_m.group(1)] = k + 1
                    break

    # Second pass: functions and bare table assignments
    for idx, line in enumerate(lines):
        stripped = line.strip()
        block = preceding_block(blocks_by_end, lines, idx)
        tags = tag_map(block) if block else {}

        assign_m = ASSIGN_TABLE_RE.match(stripped)
        if assign_m:
            parsed.assignments[assign_m.group(1)] = idx + 1

        fn_m = FN_RE.match(stripped)
        fn_g = None if fn_m else FN_GLOBAL_RE.match(stripped)
        if not fn_m and not fn_g:
            continue

        if fn_m:
            is_local, receiver, sep, fname, args = fn_m.groups()
            if is_local.strip():
                # still document local stubs — they are the public API in meta
                pass
            resolved = parsed.local_aliases.get(receiver, receiver)
            if sep == ":":
                kind = "method"
                full = f"{resolved}:{fname}"
            else:
                kind = "static"
                full = f"{resolved}.{fname}"
            signature = f"{full}({args.strip()})"
        else:
            is_local, fname, args = fn_g.groups()
            receiver = ""
            resolved = ""
            kind = "function"
            full = fname
            signature = f"{fname}({args.strip()})"

        func = Function(
            name=fname if fn_m else full,
            full_name=full,
            kind=kind,
            receiver=resolved,
            params=parse_params(tags),
            returns=parse_returns(tags),
            description=block.description if block else "",
            realm=block.realm if block else "",
            overloads=list(tags.get("overload", [])),
            visibility=visibility_from_tags(tags),
            nodiscard="nodiscard" in tags,
            async_="async" in tags,
            source=rel,
            line=(block.start_line if block else idx + 1),
            signature=signature,
        )

        # fill params from signature if none annotated
        if not func.params and args.strip():
            for part in args.split(","):
                part = part.strip()
                if not part or part == "...":
                    if part == "...":
                        func.params.append(Param(name="...", type="any"))
                    continue
                func.params.append(Param(name=part, type="any"))

        parsed.functions.append(func)

        if resolved and resolved in parsed.classes:
            if kind == "method":
                parsed.classes[resolved].methods.append(func)
            else:
                parsed.classes[resolved].statics.append(func)
        elif resolved:
            # create placeholder class/library bucket for dotted receivers
            info = parsed.classes.setdefault(
                resolved, ClassInfo(name=resolved, source=rel, line=func.line)
            )
            if kind == "method":
                info.methods.append(func)
            else:
                info.statics.append(func)

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
    "thread",
    "userdata",
    "lightuserdata",
}


def inherits_object(name: str, classes: dict[str, ClassInfo], seen: set[str] | None = None) -> bool:
    if seen is None:
        seen = set()
    if name in seen:
        return False
    seen.add(name)
    if name == "Object" or name.endswith(".Object"):
        return True
    info = classes.get(name)
    if not info:
        return False
    for parent in info.parents:
        if parent == "Object" or parent.endswith(".Object"):
            return True
        if inherits_object(parent, classes, seen):
            return True
    return False


def is_class_companion(info: ClassInfo) -> bool:
    """True for constructible class tables (*Class / inherits Class)."""
    if info.name.endswith("Class"):
        return True
    return any(p == "Class" or p.endswith("Class") for p in info.parents)


def overload_instance_type(overload: str) -> str | None:
    m = re.search(r"fun\s*\(.*\)\s*:\s*([A-Za-z_][\w.]*)", overload)
    if not m:
        return None
    ret = strip_generic(m.group(1))
    if ret.lower() in PRIMITIVE_TYPES or ret in PRIMITIVE_TYPES:
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
        m = re.match(r"call\s*:\s*([A-Za-z_][\w.<>]*)", op)
        if m:
            ret = strip_generic(m.group(1))
            if ret.lower() not in PRIMITIVE_TYPES and ret not in PRIMITIVE_TYPES:
                return ret

    # *Class naming / parent list fallback
    for p in info.parents:
        if p not in ("Class", "Object") and not p.endswith("Class"):
            return p
    if info.name.endswith("Class"):
        return info.name[: -len("Class")] or None
    return None


def looks_like_ctor_alias(name: str, classes: dict[str, ClassInfo]) -> str | None:
    """Map File/CRC16 assignment buckets to fs.File / checksum.CRC16 instances."""
    short = base_name(name)
    candidates = [
        n for n, c in classes.items()
        if c.is_class and base_name(n) == short
    ]
    if len(candidates) == 1:
        return candidates[0]
    # exact preferred
    if name in classes and classes[name].is_class:
        return name
    return None


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
        classes[instance].is_class = True
        classes[instance].class_of = companion
        comp = classes[companion]
        classes[instance].overloads = list(
            dict.fromkeys(classes[instance].overloads + comp.overloads)
        )
        classes[instance].operators = list(
            dict.fromkeys(classes[instance].operators + comp.operators)
        )
        if not classes[instance].description and comp.description:
            classes[instance].description = comp.description
        if not classes[instance].realm and comp.realm:
            classes[instance].realm = comp.realm

        classes[companion].is_class = False
        classes[companion].is_library = False

    # Resolve constructor global names (File = {} for fs.File, CRC16 = {}, Queue = {})
    for instance, companion in companions.items():
        short = base_name(instance)
        ctor_name = None
        for assign_name in assignments:
            if assign_name == instance or assign_name.endswith("." + short):
                ctor_name = assign_name
                break
        if ctor_name is None:
            for assign_name in assignments:
                if assign_name == short:
                    ctor_name = assign_name
                    break
        classes[instance].constructor = ctor_name or short

        # Merge methods/statics from local stub name, instance name, and ctor alias
        merge_from = {instance, classes[instance].constructor, companion}
        # local stubs are already resolved into instance methods during parse;
        # also merge PascalCase alias buckets (File, CRC16)
        for fname, finfo in list(classes.items()):
            if fname in merge_from or (
                not finfo.is_class
                and not finfo.instance_of
                and base_name(fname) == short
                and (finfo.statics or finfo.methods)
            ):
                for s in finfo.statics:
                    if s.full_name not in {x.full_name for x in classes[instance].statics}:
                        classes[instance].statics.append(s)
                for m in finfo.methods:
                    if m.full_name not in {x.full_name for x in classes[instance].methods}:
                        classes[instance].methods.append(m)

    # Object types with methods are classes even without a discovered companion
    for name, info in classes.items():
        if info.instance_of or info.is_class:
            continue
        if name in ("Object", "Class") or name.endswith("Class"):
            continue
        if inherits_object(name, classes) and info.methods:
            info.is_class = True
            if not info.constructor:
                info.constructor = base_name(name)

    # Merge LuaLS builtin *lib annotations (stringlib → string, bitlib → bit)
    for name, info in list(classes.items()):
        if name.endswith("lib") and len(name) > 3:
            short = name[: -len("lib")]
            if short in classes or short in assignments:
                target = classes.setdefault(short, ClassInfo(name=short, source=info.source))
                if not target.description:
                    target.description = info.description
                if not target.realm:
                    target.realm = info.realm
                target.fields.extend(info.fields)
                target.statics.extend(info.statics)

    # Libraries: namespaces with static APIs that are not class ctor aliases
    for name, info in classes.items():
        if info.instance_of or info.is_class or name.endswith("Class"):
            continue
        if name.endswith("lib") and name[: -len("lib")] in classes:
            continue
        if inherits_object(name, classes):
            continue

        alias_of = looks_like_ctor_alias(name, classes)
        if alias_of and alias_of != name:
            # fold into the real class; do not emit as library
            target = classes[alias_of]
            for s in info.statics:
                if s.full_name not in {x.full_name for x in target.statics}:
                    target.statics.append(s)
            for m in info.methods:
                if m.full_name not in {x.full_name for x in target.methods}:
                    target.methods.append(m)
            if not target.constructor or target.constructor == base_name(alias_of):
                target.constructor = name if name in assignments else target.constructor
            continue

        has_api = bool(info.statics) or bool(info.fields) or bool(info.overloads)
        assigned = name in assignments
        # callable library tables (crypto.hkdf) keep overloads but stay libraries
        if has_api and (assigned or info.statics or info.overloads):
            if name[:1].islower() or "." in name or (assigned and not name[:1].isupper()):
                info.is_library = True
            elif assigned and info.statics and not looks_like_ctor_alias(name, classes):
                info.is_library = True


def build_libraries(
    classes: dict[str, ClassInfo], free_functions: list[Function]
) -> dict[str, LibraryInfo]:
    libraries: dict[str, LibraryInfo] = {}

    for name, info in classes.items():
        if not info.is_library:
            continue
        # skip PascalCase ctor aliases that slipped through
        if name[:1].isupper() and "." not in name and not info.description and len(info.statics) <= 2:
            alias = looks_like_ctor_alias(name, classes)
            if alias:
                continue
        libraries[name] = LibraryInfo(
            name=name,
            description=info.description,
            realm=info.realm,
            functions=list(info.statics),
            fields=[f for f in info.fields if f.visibility == "public"],
            source=info.source,
            line=info.line,
        )

    # nest classes under an existing library prefix (crypto.SHA256 -> crypto)
    for name, info in classes.items():
        if not info.is_class or "." not in name:
            continue
        prefix = name.rsplit(".", 1)[0]
        while True:
            if prefix in libraries:
                libraries[prefix].nested_classes.append(name)
                break
            if "." not in prefix:
                # create a lightweight namespace page for known lowercase roots
                if prefix[:1].islower():
                    libraries.setdefault(
                        prefix,
                        LibraryInfo(name=prefix, description=f"Namespace `{prefix}`."),
                    ).nested_classes.append(name)
                break
            prefix = prefix.rsplit(".", 1)[0]

    globals_fn = [f for f in free_functions if f.kind == "function"]
    if globals_fn:
        libraries.setdefault(
            "_globals",
            LibraryInfo(
                name="_globals",
                description="Global functions in the dreamwork environment.",
            ),
        ).functions.extend(globals_fn)

    for lib in libraries.values():
        lib.nested_classes = sorted(set(lib.nested_classes))
        lib.functions.sort(key=lambda f: f.full_name.lower())

    return libraries


# ---------------------------------------------------------------------------
# HTML rendering
# ---------------------------------------------------------------------------

STYLE_CSS = r"""
:root {
  --bg: #ffffff;
  --bg-sidebar: #f6f7f9;
  --bg-hover: #eceff3;
  --bg-code: #f0f2f5;
  --border: #e2e5eb;
  --text: #15202b;
  --text-muted: #5c6b7a;
  --accent: #0f766e;
  --accent-soft: #ccfbf1;
  --link: #0f766e;
  --realm: #9a3412;
  --realm-bg: #ffedd5;
  --class: #1d4ed8;
  --lib: #0f766e;
  --fn: #7c3aed;
  --shadow: 0 1px 2px rgba(15, 23, 42, 0.04);
  --sidebar-w: 300px;
  --font: "IBM Plex Sans", "Segoe UI", sans-serif;
  --font-mono: "IBM Plex Mono", "Menlo", monospace;
  --font-display: "Source Serif 4", Georgia, serif;
}

* { box-sizing: border-box; }
html, body { margin: 0; padding: 0; height: 100%; }
body {
  font-family: var(--font);
  color: var(--text);
  background: var(--bg);
  line-height: 1.55;
  display: flex;
  min-height: 100vh;
}

a { color: var(--link); text-decoration: none; }
a:hover { text-decoration: underline; }

.sidebar {
  position: sticky;
  top: 0;
  width: var(--sidebar-w);
  min-width: var(--sidebar-w);
  height: 100vh;
  overflow: auto;
  background: var(--bg-sidebar);
  border-right: 1px solid var(--border);
  padding: 1rem 0.85rem 2rem;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.brand {
  font-family: var(--font-display);
  font-size: 1.25rem;
  font-weight: 600;
  color: var(--text);
  padding: 0.25rem 0.5rem;
  letter-spacing: -0.02em;
}
.brand span { color: var(--accent); }
.brand-sub {
  font-size: 0.75rem;
  color: var(--text-muted);
  padding: 0 0.5rem 0.5rem;
}

.search-wrap { position: relative; padding: 0 0.35rem; }
.search-wrap input {
  width: 100%;
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 0.55rem 0.75rem;
  font: inherit;
  font-size: 0.9rem;
  background: var(--bg);
  box-shadow: var(--shadow);
}
.search-wrap input:focus {
  outline: 2px solid var(--accent-soft);
  border-color: var(--accent);
}
.search-results {
  display: none;
  position: absolute;
  left: 0.35rem; right: 0.35rem;
  top: calc(100% + 4px);
  max-height: 60vh;
  overflow: auto;
  background: var(--bg);
  border: 1px solid var(--border);
  border-radius: 8px;
  box-shadow: 0 12px 32px rgba(15, 23, 42, 0.12);
  z-index: 20;
}
.search-results.open { display: block; }
.search-hit {
  display: block;
  padding: 0.55rem 0.75rem;
  border-bottom: 1px solid var(--border);
  color: inherit;
  text-decoration: none;
}
.search-hit:hover { background: var(--bg-hover); text-decoration: none; }
.search-hit .kind {
  font-size: 0.7rem;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--text-muted);
}
.search-hit .name { font-weight: 600; font-family: var(--font-mono); font-size: 0.85rem; }
.search-hit .sum { font-size: 0.8rem; color: var(--text-muted); margin-top: 0.15rem; }

.nav-section { margin-top: 0.5rem; }
.nav-section h3 {
  margin: 0.75rem 0.5rem 0.35rem;
  font-size: 0.7rem;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--text-muted);
  font-weight: 600;
}
.nav-section a {
  display: block;
  padding: 0.28rem 0.55rem;
  border-radius: 6px;
  color: var(--text);
  font-size: 0.88rem;
  font-family: var(--font-mono);
  text-decoration: none;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.nav-section a:hover, .nav-section a.active {
  background: var(--bg-hover);
  text-decoration: none;
}
.nav-section a.active { color: var(--accent); font-weight: 600; }

.content {
  flex: 1;
  min-width: 0;
  padding: 2rem 2.5rem 4rem;
  max-width: 920px;
}

.crumbs {
  font-size: 0.85rem;
  color: var(--text-muted);
  margin-bottom: 1rem;
}
.crumbs a { color: var(--text-muted); }

h1 {
  font-family: var(--font-display);
  font-size: 2rem;
  font-weight: 600;
  margin: 0 0 0.35rem;
  letter-spacing: -0.02em;
  line-height: 1.2;
}
h2 {
  font-family: var(--font-display);
  font-size: 1.35rem;
  margin: 2rem 0 0.75rem;
  padding-top: 0.5rem;
  border-top: 1px solid var(--border);
  font-weight: 600;
}
h3 {
  font-size: 1.05rem;
  margin: 1.25rem 0 0.4rem;
  font-family: var(--font-mono);
  font-weight: 600;
}

.meta-row {
  display: flex;
  flex-wrap: wrap;
  gap: 0.4rem;
  margin: 0.5rem 0 1rem;
  align-items: center;
}
.badge {
  display: inline-block;
  font-size: 0.72rem;
  font-weight: 600;
  padding: 0.15rem 0.45rem;
  border-radius: 999px;
  background: var(--bg-code);
  color: var(--text-muted);
  font-family: var(--font-mono);
}
.badge.realm { background: var(--realm-bg); color: var(--realm); }
.badge.class { background: #dbeafe; color: var(--class); }
.badge.lib { background: var(--accent-soft); color: var(--accent); }
.badge.fn { background: #ede9fe; color: var(--fn); }

.lead {
  font-size: 1.05rem;
  color: var(--text);
  margin: 0 0 1.25rem;
  white-space: pre-wrap;
}
.lead code, .prose code, td code, li code {
  font-family: var(--font-mono);
  font-size: 0.88em;
  background: var(--bg-code);
  padding: 0.1em 0.35em;
  border-radius: 4px;
}

.prose { white-space: pre-wrap; margin: 0.35rem 0 0.75rem; color: var(--text); }
.prose p { margin: 0.4rem 0; white-space: normal; }

.sig {
  font-family: var(--font-mono);
  font-size: 0.9rem;
  background: var(--bg-code);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 0.75rem 1rem;
  overflow-x: auto;
  margin: 0.5rem 0 0.75rem;
}

table.api {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.9rem;
  margin: 0.5rem 0 1rem;
}
table.api th, table.api td {
  text-align: left;
  padding: 0.45rem 0.6rem;
  border-bottom: 1px solid var(--border);
  vertical-align: top;
}
table.api th {
  color: var(--text-muted);
  font-weight: 600;
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

.member {
  padding: 0.85rem 0;
  border-bottom: 1px solid var(--border);
}
.member:target {
  background: #fffbeb;
  margin: 0 -0.75rem;
  padding-left: 0.75rem;
  padding-right: 0.75rem;
  border-radius: 8px;
}
.member h3 { margin-top: 0; }
.member h3 a { color: inherit; text-decoration: none; }
.member h3 a:hover { color: var(--accent); }

.parents { font-family: var(--font-mono); font-size: 0.9rem; color: var(--text-muted); }

.card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 0.75rem;
  margin: 1rem 0 2rem;
}
.card {
  border: 1px solid var(--border);
  border-radius: 10px;
  padding: 0.85rem 1rem;
  background: var(--bg);
  box-shadow: var(--shadow);
  text-decoration: none;
  color: inherit;
  display: block;
}
.card:hover { border-color: var(--accent); text-decoration: none; }
.card .label { font-size: 0.7rem; text-transform: uppercase; letter-spacing: 0.05em; color: var(--text-muted); }
.card .title { font-family: var(--font-mono); font-weight: 600; margin: 0.2rem 0; }
.card .sum { font-size: 0.82rem; color: var(--text-muted); display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }

.toc { margin: 1rem 0 2rem; padding: 0.75rem 1rem; background: var(--bg-sidebar); border-radius: 8px; }
.toc a { display: inline-block; margin: 0.15rem 0.5rem 0.15rem 0; font-family: var(--font-mono); font-size: 0.85rem; }

footer.page-foot {
  margin-top: 3rem;
  padding-top: 1rem;
  border-top: 1px solid var(--border);
  font-size: 0.8rem;
  color: var(--text-muted);
}

.menu-toggle {
  display: none;
  position: fixed;
  top: 0.75rem;
  right: 0.75rem;
  z-index: 30;
  border: 1px solid var(--border);
  background: var(--bg);
  border-radius: 8px;
  padding: 0.45rem 0.7rem;
  font: inherit;
  box-shadow: var(--shadow);
}

@media (max-width: 860px) {
  body { flex-direction: column; }
  .menu-toggle { display: block; }
  .sidebar {
    position: fixed;
    inset: 0 auto 0 0;
    transform: translateX(-105%);
    transition: transform 0.2s ease;
    z-index: 25;
    box-shadow: 8px 0 24px rgba(15,23,42,0.12);
  }
  .sidebar.open { transform: translateX(0); }
  .content { padding: 1.25rem 1.1rem 3rem; max-width: none; }
}
"""

APP_JS = r"""
(function () {
  const input = document.getElementById("doc-search");
  const results = document.getElementById("search-results");
  const toggle = document.getElementById("menu-toggle");
  const sidebar = document.querySelector(".sidebar");
  if (!input || !results) return;

  let index = null;
  let base = document.body.getAttribute("data-base") || "";

  fetch(base + "search-index.json")
    .then((r) => r.json())
    .then((data) => { index = data; })
    .catch(() => { index = []; });

  function score(item, q) {
    const name = item.name.toLowerCase();
    const full = (item.full || item.name).toLowerCase();
    if (name === q) return 100;
    if (full === q) return 95;
    if (name.startsWith(q)) return 80;
    if (full.startsWith(q)) return 75;
    if (name.includes(q)) return 50;
    if (full.includes(q)) return 45;
    if ((item.summary || "").toLowerCase().includes(q)) return 20;
    return 0;
  }

  function render(q) {
    if (!index || !q) {
      results.classList.remove("open");
      results.innerHTML = "";
      return;
    }
    const hits = index
      .map((item) => ({ item, s: score(item, q) }))
      .filter((x) => x.s > 0)
      .sort((a, b) => b.s - a.s || a.item.name.localeCompare(b.item.name))
      .slice(0, 40);

    if (!hits.length) {
      results.innerHTML = '<div class="search-hit"><div class="sum">No matches</div></div>';
      results.classList.add("open");
      return;
    }

    results.innerHTML = hits.map(({ item }) => {
      const href = base + item.href;
      return (
        '<a class="search-hit" href="' + href + '">' +
          '<div class="kind">' + item.kind + '</div>' +
          '<div class="name">' + escapeHtml(item.full || item.name) + '</div>' +
          (item.summary ? '<div class="sum">' + escapeHtml(item.summary) + '</div>' : '') +
        '</a>'
      );
    }).join("");
    results.classList.add("open");
  }

  function escapeHtml(s) {
    return String(s)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  let timer = null;
  input.addEventListener("input", () => {
    clearTimeout(timer);
    const q = input.value.trim().toLowerCase();
    timer = setTimeout(() => render(q), 80);
  });
  input.addEventListener("keydown", (e) => {
    if (e.key === "Escape") {
      results.classList.remove("open");
      input.blur();
    }
  });
  document.addEventListener("click", (e) => {
    if (!results.contains(e.target) && e.target !== input) {
      results.classList.remove("open");
    }
  });

  if (toggle && sidebar) {
    toggle.addEventListener("click", () => sidebar.classList.toggle("open"));
  }
})();
"""


def md_lite(text: str) -> str:
    """Minimal formatting: backticks, existing indentation preserved via pre-wrap."""
    if not text:
        return ""
    # escape first, then restore code spans
    escaped = escape(text)
    escaped = re.sub(r"`([^`]+)`", r"<code>\1</code>", escaped)
    # simple paragraphs for blank-line separated blocks when no heavy pre needed
    return f'<div class="prose">{escaped}</div>'


def first_sentence(text: str, limit: int = 140) -> str:
    if not text:
        return ""
    line = text.strip().split("\n", 1)[0].strip()
    if len(line) > limit:
        return line[: limit - 1] + "…"
    return line


def slugify(name: str) -> str:
    return re.sub(r"[^\w.-]+", "_", name)


def page_shell(
    title: str,
    body: str,
    nav_libs: list[tuple[str, str]],
    nav_classes: list[tuple[str, str]],
    base: str,
    active: str = "",
) -> str:
    def nav_links(items: list[tuple[str, str]], section: str) -> str:
        out = []
        for name, href in items:
            cls = ' class="active"' if active == f"{section}:{name}" else ""
            out.append(f'<a href="{escape(base + href)}"{cls}>{escape(name)}</a>')
        return "\n".join(out)

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{escape(title)} · dreamwork</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;600&family=IBM+Plex+Sans:wght@400;600&family=Source+Serif+4:opsz,wght@8..60,600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="{escape(base)}assets/style.css">
</head>
<body data-base="{escape(base)}">
<button class="menu-toggle" id="menu-toggle" type="button">Menu</button>
<aside class="sidebar">
  <a class="brand" href="{escape(base)}index.html">dream<span>work</span></a>
  <div class="brand-sub">API reference</div>
  <div class="search-wrap">
    <input id="doc-search" type="search" placeholder="Search libraries, classes, functions…" autocomplete="off">
    <div id="search-results" class="search-results"></div>
  </div>
  <nav class="nav-section">
    <h3>Libraries</h3>
    {nav_links(nav_libs, "lib")}
  </nav>
  <nav class="nav-section">
    <h3>Classes</h3>
    {nav_links(nav_classes, "class")}
  </nav>
</aside>
<main class="content">
{body}
<footer class="page-foot">Generated from the dreamwork <code>meta</code> branch.</footer>
</main>
<script src="{escape(base)}assets/app.js"></script>
</body>
</html>
"""


def render_params_table(params: list[Param]) -> str:
    if not params:
        return ""
    rows = []
    for p in params:
        opt = "?" if p.optional else ""
        rows.append(
            f"<tr><td><code>{escape(p.name)}{opt}</code></td>"
            f"<td><code>{escape(p.type)}</code></td>"
            f"<td>{escape(p.description)}</td></tr>"
        )
    return (
        '<table class="api"><thead><tr><th>Name</th><th>Type</th><th>Description</th></tr></thead>'
        f"<tbody>{''.join(rows)}</tbody></table>"
    )


def render_returns_table(returns: list[Return]) -> str:
    if not returns:
        return ""
    rows = []
    for r in returns:
        rows.append(
            f"<tr><td><code>{escape(r.type)}</code></td>"
            f"<td><code>{escape(r.name)}</code></td>"
            f"<td>{escape(r.description)}</td></tr>"
        )
    return (
        '<table class="api"><thead><tr><th>Type</th><th>Name</th><th>Description</th></tr></thead>'
        f"<tbody>{''.join(rows)}</tbody></table>"
    )


def render_function_block(fn: Function) -> str:
    if fn.visibility != "public":
        return ""
    anchor = slugify(fn.full_name)
    badges = []
    if fn.realm:
        badges.append(f'<span class="badge realm">{escape(fn.realm)}</span>')
    badges.append(f'<span class="badge fn">{escape(fn.kind)}</span>')
    if fn.nodiscard:
        badges.append('<span class="badge">nodiscard</span>')
    if fn.async_:
        badges.append('<span class="badge">async</span>')

    overloads = ""
    if fn.overloads:
        overloads = "<div class=\"sig\">" + "<br>".join(
            escape(o) for o in fn.overloads
        ) + "</div>"

    return f"""
<article class="member" id="{escape(anchor)}">
  <h3><a href="#{escape(anchor)}">{escape(fn.full_name)}</a></h3>
  <div class="meta-row">{''.join(badges)}</div>
  <div class="sig">{escape(fn.signature)}</div>
  {overloads}
  {md_lite(fn.description)}
  {"<h4>Parameters</h4>" + render_params_table(fn.params) if fn.params else ""}
  {"<h4>Returns</h4>" + render_returns_table(fn.returns) if fn.returns else ""}
</article>
"""


def render_fields(fields: list[Field]) -> str:
    public = [f for f in fields if f.visibility == "public"]
    if not public:
        return ""
    rows = []
    for f in public:
        rows.append(
            f"<tr id=\"field-{escape(slugify(f.name))}\">"
            f"<td><code>{escape(f.name)}</code></td>"
            f"<td><code>{escape(f.type)}</code></td>"
            f"<td>{escape(f.description)}</td></tr>"
        )
    return (
        "<h2>Fields</h2>"
        '<table class="api"><thead><tr><th>Name</th><th>Type</th><th>Description</th></tr></thead>'
        f"<tbody>{''.join(rows)}</tbody></table>"
    )


def write_docs(
    out: Path,
    libraries: dict[str, LibraryInfo],
    classes: dict[str, ClassInfo],
    aliases: list[AliasInfo],
    verbose: bool = False,
) -> None:
    if out.exists():
        shutil.rmtree(out)
    assets = out / "assets"
    assets.mkdir(parents=True)
    (assets / "style.css").write_text(STYLE_CSS, encoding="utf-8")
    (assets / "app.js").write_text(APP_JS, encoding="utf-8")

    (out / "library").mkdir()
    (out / "class").mkdir()

    # pages maps
    lib_pages = {
        name: f"library/{slugify(name)}.html"
        for name, lib in libraries.items()
        if name != "_globals" or lib.functions
    }
    if "_globals" in libraries:
        lib_pages["_globals"] = "library/_globals.html"

    class_pages = {
        name: f"class/{slugify(name)}.html"
        for name, info in classes.items()
        if info.is_class
    }

    nav_libs = sorted(
        ((name if name != "_globals" else "globals", href) for name, href in lib_pages.items()),
        key=lambda x: x[0].lower(),
    )
    nav_classes = sorted(
        ((name, href) for name, href in class_pages.items()),
        key=lambda x: x[0].lower(),
    )

    search: list[dict[str, Any]] = []

    def add_search(name: str, kind: str, href: str, summary: str = "", full: str = "") -> None:
        search.append(
            {
                "name": name,
                "full": full or name,
                "kind": kind,
                "href": href,
                "summary": first_sentence(summary),
            }
        )

    # index
    lib_cards = []
    for name, href in nav_libs:
        real = "_globals" if name == "globals" else name
        lib = libraries[real]
        lib_cards.append(
            f'<a class="card" href="{escape(href)}"><div class="label">library</div>'
            f'<div class="title">{escape(name)}</div>'
            f'<div class="sum">{escape(first_sentence(lib.description))}</div></a>'
        )
        add_search(name, "library", href, lib.description)

    class_cards = []
    for name, href in nav_classes[:48]:
        info = classes[name]
        class_cards.append(
            f'<a class="card" href="{escape(href)}"><div class="label">class</div>'
            f'<div class="title">{escape(name)}</div>'
            f'<div class="sum">{escape(first_sentence(info.description))}</div></a>'
        )

    for name, href in nav_classes:
        add_search(name, "class", href, classes[name].description)

    index_body = f"""
<div class="crumbs">docs</div>
<h1>dreamwork API</h1>
<p class="lead">GitBook-style reference for the dreamwork <code>std</code> environment —
libraries, constructible classes (callable tables that return objects), functions and methods.</p>
<div class="meta-row">
  <span class="badge lib">{len(lib_pages)} libraries</span>
  <span class="badge class">{len(class_pages)} classes</span>
</div>
<h2>Libraries</h2>
<div class="card-grid">{''.join(lib_cards)}</div>
<h2>Classes</h2>
<p class="prose">Classes inherit from <code>Object</code> and are created by calling their class table
(<code>---@overload fun(...): T</code>).</p>
<div class="card-grid">{''.join(class_cards)}</div>
{f"<p class=\"prose\">{len(nav_classes) - 48} more classes in the sidebar.</p>" if len(nav_classes) > 48 else ""}
"""
    (out / "index.html").write_text(
        page_shell("API", index_body, nav_libs, nav_classes, base=""),
        encoding="utf-8",
    )

    # library pages
    for name, lib in libraries.items():
        if name not in lib_pages:
            continue
        href = lib_pages[name]
        display = "globals" if name == "_globals" else name
        base = "../"
        badges = ['<span class="badge lib">library</span>']
        if lib.realm:
            badges.append(f'<span class="badge realm">{escape(lib.realm)}</span>')

        nested = ""
        if lib.nested_classes:
            links = []
            for cn in lib.nested_classes:
                if cn in class_pages:
                    links.append(
                        f'<a href="{escape(base + class_pages[cn])}">{escape(cn)}</a>'
                    )
            if links:
                nested = "<h2>Classes</h2><div class=\"toc\">" + " · ".join(links) + "</div>"

        fields_html = render_fields(lib.fields)
        fns = "".join(render_function_block(fn) for fn in lib.functions)
        for fn in lib.functions:
            add_search(fn.name, "function", f"{href}#{slugify(fn.full_name)}", fn.description, fn.full_name)

        body = f"""
<div class="crumbs"><a href="{base}index.html">docs</a> / library / {escape(display)}</div>
<h1>{escape(display)}</h1>
<div class="meta-row">{''.join(badges)}</div>
{md_lite(lib.description)}
{nested}
{fields_html}
{"<h2>Functions</h2>" + fns if fns else "<p class=\"prose\">No free functions.</p>"}
"""
        (out / href).write_text(
            page_shell(display, body, nav_libs, nav_classes, base=base, active=f"lib:{display}"),
            encoding="utf-8",
        )
        if verbose:
            print(f"  library {display}")

    # class pages
    for name, info in classes.items():
        if not info.is_class or name not in class_pages:
            continue
        href = class_pages[name]
        base = "../"
        badges = ['<span class="badge class">class</span>']
        if info.realm:
            badges.append(f'<span class="badge realm">{escape(info.realm)}</span>')
        if inherits_object(name, classes):
            badges.append('<span class="badge">Object</span>')

        parents = ""
        if info.parents:
            parts = []
            for p in info.parents:
                if p in class_pages:
                    parts.append(f'<a href="{escape(base + class_pages[p])}">{escape(p)}</a>')
                else:
                    parts.append(f"<code>{escape(p)}</code>")
            parents = '<div class="parents">inherits ' + ", ".join(parts) + "</div>"

        ctor = ""
        if info.overloads or info.operators or info.constructor:
            sigs = []
            ctor_name = info.constructor or base_name(name)
            for ov in info.overloads:
                # fun(a): T → Ctor(a)
                m = re.match(r"fun\s*\((.*)\)\s*:\s*(\S+)", ov)
                if m:
                    sigs.append(f"{ctor_name}({m.group(1)}) → {m.group(2)}")
                else:
                    sigs.append(f"{ctor_name} · {ov}")
            for op in info.operators:
                if op.startswith("call"):
                    sigs.append(f"{ctor_name} · @{op}")
            if not sigs:
                sigs.append(f"{ctor_name}()")
            ctor = "<h2>Constructor</h2><div class=\"sig\">" + "<br>".join(
                escape(s) for s in sigs
            ) + "</div>"

        fields_html = render_fields(info.fields)
        methods = [m for m in info.methods if m.visibility == "public"]
        statics = [s for s in info.statics if s.visibility == "public"]
        methods.sort(key=lambda f: f.name.lower())
        statics.sort(key=lambda f: f.name.lower())

        methods_html = "".join(render_function_block(m) for m in methods)
        statics_html = "".join(render_function_block(s) for s in statics)

        for m in methods:
            add_search(m.name, "method", f"{href}#{slugify(m.full_name)}", m.description, m.full_name)
        for s in statics:
            add_search(s.name, "static", f"{href}#{slugify(s.full_name)}", s.description, s.full_name)

        body = f"""
<div class="crumbs"><a href="{base}index.html">docs</a> / class / {escape(name)}</div>
<h1>{escape(name)}</h1>
<div class="meta-row">{''.join(badges)}</div>
{parents}
{md_lite(info.description)}
{ctor}
{fields_html}
{"<h2>Methods</h2>" + methods_html if methods_html else ""}
{"<h2>Static functions</h2>" + statics_html if statics_html else ""}
"""
        (out / href).write_text(
            page_shell(name, body, nav_libs, nav_classes, base=base, active=f"class:{name}"),
            encoding="utf-8",
        )
        if verbose:
            print(f"  class {name}")

    # aliases page (optional index)
    if aliases:
        rows = []
        for a in sorted(aliases, key=lambda x: x.name.lower()):
            rows.append(
                f"<tr><td><code>{escape(a.name)}</code></td>"
                f"<td><code>{escape(a.definition)}</code></td>"
                f"<td>{escape(first_sentence(a.description))}</td></tr>"
            )
            add_search(a.name, "alias", "aliases.html", a.description)
        body = f"""
<div class="crumbs"><a href="index.html">docs</a> / aliases</div>
<h1>Aliases</h1>
<table class="api"><thead><tr><th>Name</th><th>Definition</th><th>Description</th></tr></thead>
<tbody>{''.join(rows)}</tbody></table>
"""
        (out / "aliases.html").write_text(
            page_shell("Aliases", body, nav_libs, nav_classes, base=""),
            encoding="utf-8",
        )

    (out / "search-index.json").write_text(
        json.dumps(search, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )

    if verbose:
        print(f"search entries: {len(search)}")
        print(f"wrote {out}")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def collect(meta_root: Path) -> tuple[dict[str, ClassInfo], dict[str, LibraryInfo], list[AliasInfo], list[Function]]:
    library = meta_root / "library"
    if not library.is_dir():
        raise SystemExit(f"missing library directory: {library}")

    all_classes: dict[str, ClassInfo] = {}
    all_aliases: list[AliasInfo] = []
    all_functions: list[Function] = []
    all_assignments: dict[str, int] = {}

    files = sorted(library.rglob("*.lua"))
    for path in files:
        # skip internal core mirrors if desired — still parse, they define Object/Class
        parsed = parse_file(path, library)
        for name, info in parsed.classes.items():
            if name in all_classes:
                existing = all_classes[name]
                if not existing.description:
                    existing.description = info.description
                if not existing.realm:
                    existing.realm = info.realm
                if not existing.parents:
                    existing.parents = info.parents
                existing.fields.extend(info.fields)
                existing.methods.extend(info.methods)
                existing.statics.extend(info.statics)
                existing.overloads.extend(info.overloads)
                existing.operators.extend(info.operators)
            else:
                all_classes[name] = info
        all_aliases.extend(parsed.aliases)
        all_functions.extend(parsed.functions)
        all_assignments.update(parsed.assignments)

    classify(all_classes, all_assignments)
    libraries = build_libraries(all_classes, all_functions)
    return all_classes, libraries, all_aliases, all_functions


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path, help="Meta branch root (contains library/)")
    parser.add_argument("--output", required=True, type=Path, help="Directory for the static site")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    classes, libraries, aliases, _functions = collect(args.input)

    class_count = sum(1 for c in classes.values() if c.is_class)
    lib_count = len(libraries)
    if args.verbose:
        print(f"parsed {class_count} classes, {lib_count} libraries, {len(aliases)} aliases")

    write_docs(args.output, libraries, classes, aliases, verbose=args.verbose)
    print(f"docs: {lib_count} libraries, {class_count} classes → {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

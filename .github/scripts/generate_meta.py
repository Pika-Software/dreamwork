#!/usr/bin/env python3
"""
Generates compact LuaLS meta definitions for the dreamwork `std` environment.

Packages run with `dreamwork.std` as their environment, so for package developers
`std.print` is just `print` and `dreamwork.std.Queue` is just `Queue`.
This script walks the annotated sources, keeps only the public API
(doc comments + empty stubs) and strips the `dreamwork.std` prefix everywhere.

Usage: generate_meta.py [--source <repo root>] [--output <dir>] [--verbose]
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
from dataclasses import dataclass, field
from pathlib import Path

# ---------------------------------------------------------------------------
# Naming
# ---------------------------------------------------------------------------

# std libraries that share a name with a LuaLS builtin type or library;
# LuaLS calls the builtin library classes `stringlib`, `tablelib`, etc.
# and `---@class string` / `---@class table` would leak the library functions
# into every string / table value.
BUILTIN_LIBRARIES = {
    "bit", "bit32", "coroutine", "debug", "ffi", "io", "jit",
    "math", "os", "package", "string", "table", "utf8",
}

STD_TYPE_PATTERN = re.compile(r"\bdreamwork\.std\.([A-Za-z_]\w*)((?:\.[A-Za-z_]\w*)*)")
STD_PATH_PATTERN = re.compile(r"(?<![\w.])std\.(?=[A-Za-z_])")


def rename_types(text: str) -> str:
    def replace(match: re.Match) -> str:
        name, rest = match.group(1), match.group(2)
        if not rest and name in BUILTIN_LIBRARIES:
            return name + "lib"

        return name + rest

    return STD_TYPE_PATTERN.sub(replace, text)


def transform_doc(text: str) -> str:
    """Rewrites a doc line from the `dreamwork.std` point of view to the environment one."""
    return STD_PATH_PATTERN.sub("", rename_types(text))


# ---------------------------------------------------------------------------
# Lexer
# ---------------------------------------------------------------------------

KEYWORDS = {
    "and", "break", "do", "else", "elseif", "end", "false", "for", "function", "goto", "if",
    "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while",
}

OPERATORS = ("...", "==", "~=", "<=", ">=", "..", "::", "//", "<<", ">>")

LONG_BRACKET = re.compile(r"\[(=*)\[")
NUMBER = re.compile(
    r"0[xX][0-9a-fA-F]*(?:\.[0-9a-fA-F]*)?(?:[pP][+-]?\d+)?[uUlLiI]*"
    r"|(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?[uUlLiI]*"
)
NAME = re.compile(r"[A-Za-z_]\w*")
SEPARATOR_LINE = re.compile(r"----+\s*")

# tokens after which the next token continues the same expression
CONTINUATION = {
    "=", ",", "(", "{", "[", "..", "+", "-", "*", "/", "%", "^", "#", "==", "~=", "<", ">",
    "<=", ">=", "and", "or", "not", "return", "local", "function", "in", ".", ":",
}

STATEMENT_END_KEYWORDS = {"end", "else", "elseif", "until"}

# globals that exist in every Lua environment, safe to reference from the meta files
LUA_GLOBALS = {
    "_G", "_VERSION", "assert", "bit", "collectgarbage", "coroutine", "debug", "dofile", "error",
    "gcinfo", "getfenv", "getmetatable", "io", "ipairs", "jit", "load", "loadfile", "loadstring",
    "math", "module", "newproxy", "next", "os", "package", "pairs", "pcall", "print", "rawequal",
    "rawget", "rawlen", "rawset", "require", "select", "setfenv", "setmetatable", "string", "table",
    "tonumber", "tostring", "type", "unpack", "xpcall",
}


@dataclass
class Token:
    kind: str  # name, keyword, number, string, op
    value: str
    line: int
    first: bool = False  # first token on its line
    depth: int = 0  # bracket depth
    fn_depth: int = 0  # number of enclosing function bodies
    stmt: bool = False  # starts a statement


def lex(source: str) -> tuple[list[Token], dict[int, str]]:
    tokens: list[Token] = []
    docs: dict[int, str] = {}

    i, n, line = 0, len(source), 1
    last_token_line = 0

    def push(kind: str, value: str, token_line: int):
        nonlocal last_token_line
        tokens.append(Token(kind, value, token_line, token_line != last_token_line))
        last_token_line = token_line

    while i < n:
        c = source[i]

        if c == "\n":
            line += 1
            i += 1
            continue

        if c in " \t\r\f\v":
            i += 1
            continue

        if source.startswith("--", i):
            match = LONG_BRACKET.match(source, i + 2)
            if match:
                end = source.find("]" + match.group(1) + "]", match.end())
                end = n if end < 0 else end + len(match.group(1)) + 2
                line += source.count("\n", i, end)
                i = end
                continue

            end = source.find("\n", i)
            end = n if end < 0 else end
            text = source[i:end]
            if text.startswith("---") and line != last_token_line and not SEPARATOR_LINE.fullmatch(text):
                docs[line] = text[3:].rstrip()

            i = end
            continue

        if c == "[":
            match = LONG_BRACKET.match(source, i)
            if match:
                end = source.find("]" + match.group(1) + "]", match.end())
                end = n if end < 0 else end + len(match.group(1)) + 2
                push("string", source[i:end], line)
                line += source.count("\n", i, end)
                i = end
                continue

        if c == '"' or c == "'":
            j = i + 1
            while j < n and source[j] != c:
                if source[j] == "\\":
                    j += 1
                elif source[j] == "\n":
                    break

                j += 1

            push("string", source[i:j + 1], line)
            line += source.count("\n", i, j + 1)
            i = j + 1
            continue

        if c.isdigit() or (c == "." and i + 1 < n and source[i + 1].isdigit()):
            match = NUMBER.match(source, i)
            push("number", match.group(0), line)
            i = match.end()
            continue

        if c.isalpha() or c == "_":
            match = NAME.match(source, i)
            word = match.group(0)
            push("keyword" if word in KEYWORDS else "name", word, line)
            i = match.end()
            continue

        for operator in OPERATORS:
            if source.startswith(operator, i):
                push("op", operator, line)
                i += len(operator)
                break
        else:
            push("op", c, line)
            i += 1

    annotate(tokens)
    return tokens, docs


def annotate(tokens: list[Token]):
    """Marks bracket depth, function nesting and statement starts on every token."""
    blocks: list[str] = []
    depth = fn_depth = 0
    pending_loop = False
    previous: Token | None = None

    for token in tokens:
        token.depth = depth
        token.fn_depth = fn_depth
        token.stmt = depth == 0 and (previous is None or (token.first and previous.value not in CONTINUATION))

        value = token.value
        if token.kind == "keyword":
            if value == "function":
                blocks.append("function")
                fn_depth += 1
            elif value in ("while", "for"):
                blocks.append("loop")
                pending_loop = True
            elif value == "do":
                if pending_loop:
                    pending_loop = False
                else:
                    blocks.append("do")
            elif value in ("if", "repeat"):
                blocks.append(value)
            elif value in ("end", "until") and blocks:
                if blocks.pop() == "function":
                    fn_depth -= 1

        elif token.kind == "op":
            if value in "({[":
                depth += 1
            elif value in ")}]":
                depth = max(depth - 1, 0)

        previous = token


# ---------------------------------------------------------------------------
# Statement parsing
# ---------------------------------------------------------------------------


@dataclass
class Rhs:
    kind: str  # func, literal, table, ref, expr
    value: object = None


@dataclass
class Statement:
    kind: str  # local_func, local, func, assign
    names: list[str] = field(default_factory=list)
    method: str | None = None
    params: list[str] = field(default_factory=list)
    rhs: Rhs | None = None


def parse_path(tokens: list[Token], i: int) -> tuple[list[str], int]:
    names = [tokens[i].value]
    i += 1
    while i + 1 < len(tokens) and tokens[i].value == "." and tokens[i + 1].kind == "name":
        names.append(tokens[i + 1].value)
        i += 2

    return names, i


def parse_params(tokens: list[Token], i: int) -> tuple[list[str], int]:
    params: list[str] = []
    if i >= len(tokens) or tokens[i].value != "(":
        return params, i

    i += 1
    while i < len(tokens) and tokens[i].value != ")":
        if tokens[i].kind == "name" or tokens[i].value == "...":
            params.append(tokens[i].value)

        i += 1

    return params, i + 1


def ends_statement(tokens: list[Token], i: int) -> bool:
    if i >= len(tokens):
        return True

    token = tokens[i]
    return token.stmt or token.value == ";" or (token.kind == "keyword" and token.value in STATEMENT_END_KEYWORDS)


def ends_field(tokens: list[Token], i: int) -> bool:
    return i >= len(tokens) or tokens[i].value in (",", ";", "}")


def parse_table(tokens: list[Token], i: int) -> tuple[list[tuple[Token, Rhs]], int]:
    """Parses the `name = value` fields of the table constructor at `i`, returns them and the index after `}`."""
    depth = tokens[i].depth + 1
    fields: list[tuple[Token, Rhs]] = []

    k = i + 1
    while k < len(tokens) and not (tokens[k].value == "}" and tokens[k].depth == depth):
        token = tokens[k]
        if token.depth == depth and token.kind == "name" and tokens[k - 1].value in ("{", ",", ";") \
                and k + 1 < len(tokens) and tokens[k + 1].value == "=":
            fields.append((token, parse_rhs(tokens, k + 2, ends_field)))

        k += 1

    return fields, k + 1


def parse_rhs(tokens: list[Token], i: int, ends=ends_statement) -> Rhs:
    if i >= len(tokens):
        return Rhs("expr")

    token = tokens[i]

    if token.kind == "keyword" and token.value == "function":
        params, _ = parse_params(tokens, i + 1)
        return Rhs("func", params)

    if (token.kind in ("number", "string") or token.value in ("true", "false", "nil")) and ends(tokens, i + 1):
        return Rhs("literal", token.value)

    if token.value == "{":
        fields, j = parse_table(tokens, i)
        if ends(tokens, j):
            return Rhs("table", fields)

    if token.kind == "name":
        names, j = parse_path(tokens, i)
        if ends(tokens, j):
            return Rhs("ref", names)

    return Rhs("expr")


def parse_statement(tokens: list[Token], i: int) -> Statement | None:
    token = tokens[i]

    if token.value == "local" and token.kind == "keyword":
        if i + 2 < len(tokens) and tokens[i + 1].value == "function":
            params, _ = parse_params(tokens, i + 3)
            return Statement("local_func", [tokens[i + 2].value], params=params)

        names: list[str] = []
        i += 1
        while i < len(tokens) and tokens[i].kind == "name":
            names.append(tokens[i].value)
            i += 1
            if i < len(tokens) and tokens[i].value == ",":
                i += 1
            else:
                break

        rhs = parse_rhs(tokens, i + 1) if i < len(tokens) and tokens[i].value == "=" else None
        return Statement("local", names, rhs=rhs)

    if token.value == "function" and token.kind == "keyword":
        if i + 1 >= len(tokens) or tokens[i + 1].kind != "name":
            return None

        names, j = parse_path(tokens, i + 1)
        method = None
        if j + 1 < len(tokens) and tokens[j].value == ":":
            method = tokens[j + 1].value
            j += 2

        params, _ = parse_params(tokens, j)
        return Statement("func", names, method, params)

    if token.kind == "name":
        names, j = parse_path(tokens, i)
        if j < len(tokens) and tokens[j].value == "=":
            return Statement("assign", names, rhs=parse_rhs(tokens, j + 1))

    return None


# ---------------------------------------------------------------------------
# Doc blocks
# ---------------------------------------------------------------------------

CLASS_TAG = re.compile(r"^\s*@class\s+(?:\([^)]*\)\s*)?([^\s:<]+)")
TYPE_DEFINITION_TAG = re.compile(r"^\s*@(?:class|alias|enum)\s+(?:\([^)]*\)\s*)?([^\s:<]+)")
FIELD_TAG = re.compile(r"^\s*@field\s+(?:(public|private|protected|package)\s+)?([A-Za-z_]\w*)(\??)\s+(.*)$")
PRIVATE_TAG = re.compile(r"^\s*@private\b")
DROPPED_TAG = re.compile(r"^\s*@diagnostic\b")
TYPE_TAG = re.compile(r"^\s*@type\b")
FUNCTION_TAG = re.compile(r"^\s*@(param|return|overload)\b")
PARAM_TAG = re.compile(r"^\s*@param\s+([A-Za-z_]\w*|\.\.\.)")
SELF_ALIAS = re.compile(r"^\s*@alias\s+(\S+)\s+(\S+)\s*$")
CLASS_PARENTS = re.compile(r"^(\s*@class\s+(?:\([^)]*\)\s*)?)([^\s:]+)(\s*:\s*)(.*)$")


@dataclass
class Doc:
    lines: list[str]

    @property
    def class_name(self) -> str | None:
        for line in self.lines:
            match = CLASS_TAG.match(line)
            if match:
                return match.group(1)

        return None

    @property
    def defines_types(self) -> bool:
        return any(TYPE_DEFINITION_TAG.match(line) for line in self.lines)

    @property
    def defined_names(self) -> list[str]:
        return [match.group(1) for match in map(TYPE_DEFINITION_TAG.match, self.lines) if match]

    @property
    def is_empty(self) -> bool:
        return not any(line.strip() and not DROPPED_TAG.match(line) for line in self.lines)

    @property
    def is_function(self) -> bool:
        return not self.has_type and not self.defines_types and any(FUNCTION_TAG.match(line) for line in self.lines)

    @property
    def param_names(self) -> list[str]:
        return [match.group(1) for match in map(PARAM_TAG.match, self.lines) if match]

    @property
    def is_private(self) -> bool:
        return any(PRIVATE_TAG.match(line) for line in self.lines)

    @property
    def has_type(self) -> bool:
        return any(TYPE_TAG.match(line) for line in self.lines)

    def render(self) -> list[str]:
        rendered = []
        for line in self.lines:
            if DROPPED_TAG.match(line):
                continue

            line = transform_doc(line)

            match = SELF_ALIAS.match(line)
            if match and match.group(1) == match.group(2):
                continue

            match = CLASS_PARENTS.match(line)
            if match:
                # `---@class dreamwork.std.debug : debuglib` is `debuglib : debuglib` now
                parents = [parent for parent in match.group(4).split(",") if parent.strip() != match.group(2)]
                line = match.group(1) + match.group(2) + (match.group(3) + ",".join(parents) if parents else "")

            rendered.append("---" + line)

        return rendered


def split_type(text: str) -> tuple[str, str]:
    """Splits `<type expression> <description>` as found after `@field name`."""
    i, n = 0, len(text)
    expect_operand = True

    def skip_spaces(k: int) -> int:
        while k < n and text[k] in " \t":
            k += 1

        return k

    def balanced(k: int) -> int:
        pairs = {"(": ")", "<": ">", "[": "]", "{": "}"}
        stack = [pairs[text[k]]]
        k += 1
        while k < n and stack:
            if text[k] in pairs:
                stack.append(pairs[text[k]])
            elif text[k] == stack[-1]:
                stack.pop()
            elif text[k] in "\"'`":
                end = text.find(text[k], k + 1)
                k = n - 1 if end < 0 else end

            k += 1

        return k

    while i < n:
        i = skip_spaces(i)
        if i >= n:
            break

        if expect_operand:
            if text[i] in "\"'`":
                end = text.find(text[i], i + 1)
                i = n if end < 0 else end + 1
            elif text[i] in "({":
                i = balanced(i)
            else:
                start = i
                while i < n and (text[i].isalnum() or text[i] in "_.-"):
                    i += 1

                if text[start:i] == "fun" and i < n and text[i] == "(":
                    i = balanced(i)
                    after = skip_spaces(i)
                    if after < n and text[after] == ":":
                        i = after + 1
                        continue

                if i == start:
                    break

            while i < n and text[i] in "<[?":
                if text[i] == "?":
                    i += 1
                else:
                    i = balanced(i)

            expect_operand = False
        else:
            after = skip_spaces(i)
            if after < n and text[after] == "|":
                i = after + 1
                expect_operand = True
            else:
                break

    return text[:i].strip(), text[i:].strip()


# ---------------------------------------------------------------------------
# Extraction
# ---------------------------------------------------------------------------


@dataclass
class ClassLocal:
    name: str
    doc: Doc
    export: str | None = None  # global path the local is published as, e.g. `uuid`
    render_name: str = ""

    def display(self) -> str:
        return self.export or self.render_name or self.name


@dataclass
class LocalFunction:
    params: list[str]
    doc: Doc | None


@dataclass
class Target:
    """Where a definition lands, either a global path or a member of a local class table."""

    path: list[str]
    owner: ClassLocal | None = None

    def render(self, method: str | None = None) -> str:
        base = list(self.path)
        if self.owner is not None:
            base.insert(0, self.owner.display())

        text = ".".join(base)
        return f"{text}:{method}" if method else text

    def key(self, method: str | None = None) -> str:
        return ("local:%d:" % id(self.owner) if self.owner else "global:") + self.render(method)


@dataclass
class Item:
    doc: Doc | None
    code: str | None = None  # stub code, rendered later if it references a class local
    target: Target | None = None
    method: str | None = None
    params: list[str] | None = None
    value: object = None  # str or ClassLocal
    declares: ClassLocal | None = None
    rendered_doc: list[str] | None = None  # for synthesized docs

    @property
    def documented(self) -> bool:
        return self.rendered_doc is not None or (self.doc is not None and not self.doc.is_empty)

    def key(self) -> str | None:
        return self.target.key(self.method) if self.target is not None else None

    def render(self) -> str:
        lines = list(self.rendered_doc or (self.doc.render() if self.doc else []))

        if self.declares is not None:
            lines.append(("" if self.declares.export else "local ") + self.declares.display() + " = {}")
        elif self.params is not None:
            lines.append("function %s(%s) end" % (self.target.render(self.method), ", ".join(self.params)))
        elif self.target is not None:
            value = self.value.display() if isinstance(self.value, ClassLocal) else self.value
            lines.append("%s = %s" % (self.target.render(), value))
        elif self.code is not None:
            lines.append(self.code)

        return "\n".join(lines)


# environment bindings of a file
PATH, CLASS, FUNC, VALUE = "path", "class", "func", "value"


class FileExtractor:
    def __init__(self, path: Path, std_file: bool, stats: dict):
        self.path = path
        self.std_file = std_file
        self.stats = stats
        self.items: list[Item] = []
        self.class_locals: list[ClassLocal] = []
        self.env: dict[str, tuple] = {}
        self.nested_docs: dict[int, Doc] = {}  # docs inside expressions, e.g. table constructor fields

    # -- resolution ---------------------------------------------------------

    def resolve(self, names: list[str]) -> tuple | None:
        head, rest = names[0], names[1:]

        if head == "dreamwork" and rest[:1] == ["std"]:
            return (PATH, rest[1:])

        binding = self.env.get(head)
        if binding is None:
            return None

        kind = binding[0]
        if kind == PATH:
            return (PATH, binding[1] + rest)

        if kind == CLASS:
            return (CLASS, binding[1], rest)

        if not rest:
            return binding

        return (VALUE, None)

    def target_of(self, container: list[str], name: str) -> Target | None:
        resolved = self.resolve(container)
        if resolved is None:
            return None

        if resolved[0] == PATH:
            return Target(resolved[1] + [name])

        if resolved[0] == CLASS:
            return Target(resolved[2] + [name], resolved[1])

        return None

    def wants_class(self, class_name: str | None) -> bool:
        return self.std_file or (class_name is not None and class_name.startswith("dreamwork.std."))

    # -- emission -----------------------------------------------------------

    def emit_floating(self, doc: Doc):
        if doc.class_name == "dreamwork.std":
            self.emit_std_fields(doc)
        elif any(self.wants_class(name) for name in doc.defined_names):
            self.items.append(Item(doc))
        else:
            self.stats["dropped_docs"] += 1

    def emit_std_fields(self, doc: Doc):
        """`---@class dreamwork.std` + `---@field X` declares the global `X`."""
        for line in doc.lines:
            match = FIELD_TAG.match(line)
            if match is None or match.group(1) in ("private", "protected"):
                continue

            type_text, description = split_type(match.group(4))
            rendered = []
            if description:
                rendered += ["--- " + transform_doc(description), "---"]

            rendered.append("---@type " + rename_types(type_text) + ("?" if match.group(3) else ""))
            self.items.append(Item(None, target=Target([match.group(2)]), value="nil", rendered_doc=rendered))

    def handle(self, statement: Statement, doc: Doc | None):
        if doc is not None and doc.is_empty:
            doc = None

        if doc is not None and doc.is_private:
            if statement.kind == "local_func":
                self.env[statement.names[0]] = (VALUE, None)

            return

        kind = statement.kind

        if kind == "local_func":
            self.env[statement.names[0]] = (FUNC, LocalFunction(statement.params, doc))
            return

        if kind == "local":
            self.handle_local(statement, doc)
            return

        container, name = statement.names[:-1], statement.names[-1]
        if not container and statement.method is None:
            if kind == "func":
                # forward declared `local name` (or a helper global) defined by `function name()`
                self.env[name] = (FUNC, LocalFunction(statement.params, doc))
                return

            binding = self.env.get(name)
            if binding is not None and statement.rhs.kind == "table":
                # `local raw = std.raw; if raw == nil then raw = { ... } end`
                if binding[0] == PATH and binding[1]:
                    self.handle_assign(Target(binding[1]), statement.rhs, doc)
                    return

                if binding[0] == CLASS:
                    self.emit_fields(Target([], binding[1]), statement.rhs.value)
                    return

            # plain global, not part of the environment
            if doc is not None:
                self.emit_floating(doc)

            return

        if statement.method is not None:
            container, name = statement.names, None

        target = self.target_of(container, name) if name is not None else self.method_target(container)
        if target is None:
            if doc is not None:
                self.emit_floating(doc)

            return

        if kind == "func":
            self.items.append(Item(doc, target=target, method=statement.method, params=statement.params))
            return

        self.handle_assign(target, statement.rhs, doc)

    def method_target(self, container: list[str]) -> Target | None:
        resolved = self.resolve(container)
        if resolved is None:
            return None

        if resolved[0] == PATH and resolved[1]:
            return Target(resolved[1])

        if resolved[0] == CLASS:
            return Target(resolved[2], resolved[1])

        return None

    def handle_local(self, statement: Statement, doc: Doc | None):
        names, rhs = statement.names, statement.rhs
        if len(names) != 1:
            for name in names:
                self.env[name] = (VALUE, None)

            return

        name = names[0]
        resolved = self.resolve(rhs.value) if rhs is not None and rhs.kind == "ref" else None
        class_name = doc.class_name if doc is not None else None

        if class_name == "dreamwork.std":
            self.emit_std_fields(doc)
            self.env[name] = (PATH, [])
            return

        if class_name is not None:
            if resolved is not None and resolved[0] == PATH:
                self.env[name] = resolved
                if self.wants_class(class_name) and not self.is_trivial_class(doc, resolved[1]):
                    self.items.append(Item(doc, target=Target(resolved[1]), value="{}"))
            elif self.wants_class(class_name):
                class_local = ClassLocal(name, doc)
                self.class_locals.append(class_local)
                self.env[name] = (CLASS, class_local)
                self.items.append(Item(doc, declares=class_local))
                if rhs is not None and rhs.kind == "table":
                    self.emit_fields(Target([], class_local), rhs.value)
            else:
                self.env[name] = (VALUE, None)

            return

        if rhs is not None and rhs.kind == "func":
            self.env[name] = (FUNC, LocalFunction(rhs.value, doc))
            return

        if resolved is not None:
            self.env[name] = resolved
            return

        self.env[name] = (VALUE, doc)
        if doc is not None and doc.defines_types:
            self.emit_floating(doc)

    @staticmethod
    def is_trivial_class(doc: Doc, path: list[str]) -> bool:
        lines = [line for line in doc.lines if line.strip() and not DROPPED_TAG.match(line)]
        return len(lines) == 1 and CLASS_TAG.match(lines[0]) is not None \
            and lines[0].split()[-1] == "dreamwork.std." + ".".join(path)

    def handle_assign(self, target: Target, rhs: Rhs, doc: Doc | None):
        kind = rhs.kind

        if kind == "func":
            self.items.append(Item(doc, target=target, params=rhs.value))
            return

        if kind == "literal":
            self.items.append(Item(doc, target=target, value=rhs.value))
            return

        if kind == "table":
            self.items.append(Item(doc, target=target, value="{}"))
            self.emit_fields(target, rhs.value)
            return

        if kind == "ref":
            resolved = self.resolve(rhs.value)

            if resolved is None and rhs.value[0] in LUA_GLOBALS:
                # a Lua builtin (e.g. `std.pcall = pcall`), not a local
                if target.owner is not None or target.path != rhs.value:
                    self.items.append(Item(doc, target=target, value=".".join(rhs.value)))
                elif doc is not None:
                    self.items.append(Item(doc, target=target, value="nil"))

                return

            if resolved is None:
                resolved = (VALUE, None)

            if resolved[0] == FUNC:
                function = resolved[1]
                self.items.append(Item(doc or function.doc, target=target, params=function.params))
                return

            if resolved[0] == CLASS and not resolved[2]:
                class_local = resolved[1]
                if target.owner is None and class_local.export is None and doc is None:
                    class_local.export = target.render()
                else:
                    self.items.append(Item(doc, target=target, value=class_local))

                return

            if resolved[0] == PATH:
                if resolved[1] and resolved[1] != target.path:
                    self.items.append(Item(doc, target=target, value=".".join(resolved[1])))
                elif doc is not None:
                    self.items.append(Item(doc, target=target, value="nil"))

                return

            if resolved[0] == VALUE and resolved[1] is not None and doc is None:
                doc = resolved[1]

        if doc is None:
            self.stats["skipped_expressions"] += 1
        elif doc.is_function:
            self.items.append(Item(doc, target=target, params=doc.param_names))
        else:
            self.items.append(Item(doc, target=target, value="{}" if doc.class_name and not doc.has_type else "nil"))

    def emit_fields(self, target: Target, fields: list[tuple[Token, Rhs]]):
        for token, rhs in fields:
            doc = self.nested_docs.pop(token.line, None) if token.first else None
            if doc is not None and doc.is_empty:
                doc = None

            if doc is not None and doc.is_private:
                continue

            self.handle_assign(Target(target.path + [token.value], target.owner), rhs, doc)

    # -- driver -------------------------------------------------------------

    def run(self, source: str) -> list[Item]:
        tokens, doc_lines = lex(source)

        # group consecutive doc lines into blocks, keyed by the line after the block
        blocks: dict[int, Doc] = {}
        floating: list[tuple[int, Doc]] = []
        token_lines = {token.line for token in tokens if token.first}

        for line in sorted(doc_lines):
            if line - 1 in doc_lines:
                continue

            end, lines = line, []
            while end in doc_lines:
                lines.append(doc_lines[end])
                end += 1

            if end in token_lines:
                blocks[end] = Doc(lines)
            else:
                floating.append((line, Doc(lines)))

        events: list[tuple[int, int, object]] = [(line, 0, doc) for line, doc in floating]

        for index, token in enumerate(tokens):
            if not token.first:
                continue

            doc = blocks.pop(token.line, None)
            if token.stmt and token.fn_depth == 0:
                events.append((token.line, 1, (index, doc)))
            elif doc is not None:
                # documented, but nested in a function body or an expression,
                # table constructor fields take theirs before this event comes
                self.nested_docs[token.line] = doc
                events.append((token.line, 0, token.line))

        events.sort(key=lambda event: (event[0], event[1]))

        for _, _, payload in events:
            if isinstance(payload, Doc):
                self.emit_floating(payload)
                continue

            if isinstance(payload, int):
                doc = self.nested_docs.pop(payload, None)
                if doc is not None:
                    self.emit_floating(doc)

                continue

            index, doc = payload
            statement = parse_statement(tokens, index)
            if statement is None:
                if doc is not None:
                    self.emit_floating(doc)

                continue

            self.handle(statement, doc)

        return self.items


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

HEADER = "---@meta _\n\n"


def resolve_local_names(items: list[Item], class_locals: list[ClassLocal]):
    """Renames local class tables that would shadow a global defined in the same file."""
    globals_used = set()
    for item in items:
        if item.target is not None and item.target.owner is None and item.target.path:
            globals_used.add(item.target.path[0])

    for class_local in class_locals:
        if class_local.export is not None:
            globals_used.add(class_local.export.split(".")[0])

    for class_local in class_locals:
        name = class_local.name
        while name in globals_used:
            name = "__" + name

        class_local.render_name = name


def deduplicate(files: list[tuple[str, list[Item]]]) -> list[tuple[str, list[Item]]]:
    """Keeps documented definitions over undocumented reassignments of the same name."""
    documented: set[str] = set()
    for _, items in files:
        for item in items:
            key = item.key()
            if key is not None and item.documented:
                documented.add(key)

    seen_keys: set[str] = set()
    seen_texts: set[str] = set()
    result = []

    for name, items in files:
        kept = []
        for item in items:
            key = item.key()
            text = item.render()

            if key is not None:
                if key in documented and not item.documented:
                    continue

                if not item.documented and key in seen_keys:
                    continue

                if (key, text) in seen_texts:
                    continue

                seen_keys.add(key)
                seen_texts.add((key, text))

            kept.append(item)

        result.append((name, kept))

    return result


# sources that are kept in the tree for reference but never loaded
EXCLUDED_SOURCES = {"std/io/fs-ref.lua"}

README = """# dreamwork meta

Generated [LuaLS](https://luals.github.io) definitions for the dreamwork `std` environment,
do not edit this branch by hand, it is rebuilt from `%(branch)s` by `.github/workflows/meta.yml`.

Packages run inside `dreamwork.std`, so everything is declared as a global here:
`std.print` is `print`, `dreamwork.std.Queue` is `Queue`, and so on.

## Usage

Add the `library` folder of this branch to your workspace libraries, e.g. in `.luarc.json`:

```json
{
    "runtime.version": "LuaJIT",
    "workspace.library": [ "path/to/dreamwork-meta/library" ]
}
```

or clone the branch into a LuaLS addons folder, it is a valid addon (`config.json` + `library`).

Source commit: `%(commit)s`
"""


def copy_meta(path: Path, target: Path):
    """Copies a hand-written meta file, rewritten to the environment point of view."""
    text = path.read_text(encoding="utf-8")
    text = re.sub(r"^---@meta\b.*$", "---@meta _", text, count=1, flags=re.M)
    lines = [transform_doc(line) if line.lstrip().startswith("--") else rename_types(line) for line in text.split("\n")]

    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text("\n".join(line for line in lines if not DROPPED_TAG.match(line.lstrip()[3:])), encoding="utf-8")


def generate(source_root: Path, output: Path, verbose: bool, branch: str, commit: str) -> int:
    lua_root = source_root / "lua" / "dreamwork"
    std_root = lua_root / "std"
    meta_root = source_root / "meta"

    stats = {"dropped_docs": 0, "skipped_expressions": 0}
    files: list[tuple[str, list[Item]]] = []

    for path in sorted(lua_root.rglob("*.lua")):
        if str(path.relative_to(lua_root)) in EXCLUDED_SOURCES:
            continue

        std_file = std_root in path.parents
        name = str(path.relative_to(std_root)) if std_file else "_core/" + str(path.relative_to(lua_root))

        extractor = FileExtractor(path, std_file, stats)
        items = extractor.run(path.read_text(encoding="utf-8"))
        resolve_local_names(items, extractor.class_locals)
        files.append((name, items))

    library = output / "library"
    if library.exists():
        shutil.rmtree(library)

    written = 0

    for name, items in deduplicate(files):
        texts = [text for text in map(Item.render, items) if text]
        if not texts:
            continue

        target = library / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(HEADER + "\n\n".join(texts) + "\n", encoding="utf-8")
        written += 1

        if verbose:
            print("%-48s %4d definitions" % (name, len(texts)))

    # hand-written meta definitions: the std ones and the shared aliases (`byte`, `numberbase`, ...)
    hand_written = [(meta_root / "lua.lua", library / "_meta" / "lua.lua")]
    hand_written += [(path, library / "_meta" / path.relative_to(meta_root / "dreamwork")) for path in sorted((meta_root / "dreamwork").rglob("*.lua"))]

    for path, target in hand_written:
        if path.is_file():
            copy_meta(path, target)
            written += 1

    config = {
        "$schema": "https://raw.githubusercontent.com/LuaLS/LLS-Addons/main/schemas/addon_config.schema.json",
        "name": "dreamwork",
        "words": [],
        "files": [],
        "settings": {
            "Lua.runtime.version": "LuaJIT",
        },
    }

    (output / "config.json").write_text(json.dumps(config, indent=4) + "\n", encoding="utf-8")
    (output / "README.md").write_text(README % {"branch": branch, "commit": commit}, encoding="utf-8")

    print("generated %d meta files into %s" % (written, library))
    if verbose:
        print("undocumented expressions skipped: %d, unbound doc blocks dropped: %d" % (stats["skipped_expressions"], stats["dropped_docs"]))

    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--source", type=Path, default=Path(__file__).resolve().parents[2], help="repository root")
    parser.add_argument("--output", type=Path, default=Path("meta-out"), help="output directory")
    parser.add_argument("--branch", default="main", help="source branch name for the README")
    parser.add_argument("--commit", default="unknown", help="source commit hash for the README")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    args.output.mkdir(parents=True, exist_ok=True)
    return generate(args.source.resolve(), args.output, args.verbose, args.branch, args.commit)


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""
Reports a `lua-language-server --check_format=json` result as GitHub annotations.

Fails only on errors, warnings are mostly types referenced by the sources
but defined outside of them and should not block the meta branch.

Usage: check_meta.py <check.json> [<path prefix to strip>]
"""

import json
import sys
from urllib.parse import unquote, urlparse

SEVERITIES = {1: "error", 2: "warning", 3: "notice", 4: "notice"}


def escape_data(text: str) -> str:
    """Workflow command message escaping."""
    return text.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")


def escape_property(text: str) -> str:
    """Workflow command property escaping, `:` and `,` end a property."""
    return escape_data(text).replace(":", "%3A").replace(",", "%2C")


def main() -> int:
    with open(sys.argv[1], encoding="utf-8") as file:
        report = json.load(file)

    prefix = sys.argv[2].rstrip("/") + "/" if len(sys.argv) > 2 else ""
    errors = 0

    for uri, diagnostics in sorted(report.items()):
        path = unquote(urlparse(uri).path)
        if prefix and path.startswith(prefix):
            path = path[len(prefix):]

        for diagnostic in diagnostics:
            level = SEVERITIES.get(diagnostic.get("severity", 1), "error")
            errors += level == "error"

            start = diagnostic["range"]["start"]
            message = "%s (%s)" % (diagnostic["message"].replace("\n", " "), diagnostic.get("code", "?"))
            title = "meta/%s:%d" % (path, start["line"] + 1)
            print("::%s title=%s::%s" % (level, escape_property(title), escape_data(message)))

    total = sum(len(diagnostics) for diagnostics in report.values())
    print("%d problems, %d errors" % (total, errors))
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Reject email addresses that should not be published with the repository."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


EMAIL_PATTERN = re.compile(
    rb"(?<![A-Z0-9._%+-])([A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,})(?![A-Z0-9.-])",
    re.IGNORECASE,
)
RETINA_IMAGE_PATTERN = re.compile(
    rb"@\d+(?:\.\d+)?x\.(?:png|jpe?g|gif|webp|svg)$",
    re.IGNORECASE,
)


def repository_files() -> list[Path]:
    result = subprocess.run(
        ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
        check=True,
        stdout=subprocess.PIPE,
    )
    return [Path(item.decode()) for item in result.stdout.split(b"\0") if item]


def is_allowed(value: bytes) -> bool:
    normalized = value.lower()
    return (
        normalized == b"noreply@github.com"
        or normalized.endswith(b"@users.noreply.github.com")
        or RETINA_IMAGE_PATTERN.search(normalized) is not None
    )


def main() -> int:
    violations: list[tuple[Path, int]] = []

    for path in repository_files():
        try:
            content = path.read_bytes()
        except FileNotFoundError:
            continue
        except OSError as error:
            print(f"Unable to inspect {path}: {error}", file=sys.stderr)
            return 2

        if b"\0" in content:
            continue

        for line_number, line in enumerate(content.splitlines(), start=1):
            if any(not is_allowed(match.group(1)) for match in EMAIL_PATTERN.finditer(line)):
                violations.append((path, line_number))

    for path, line_number in violations:
        print(
            f"::error file={path.as_posix()},line={line_number}::"
            "Potential non-noreply email detected (value redacted)."
        )

    if violations:
        print(f"Privacy check failed with {len(violations)} redacted match(es).")
        return 1

    print("Privacy check passed: no non-noreply email addresses were found.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

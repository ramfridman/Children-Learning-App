#!/usr/bin/env python3
"""Prints a `flutter test --name` filter that takes every test except the one with exactly the given full name.

Usage: python3 tools/ci/exact-name-regex.py <full test name> <prefix the name must start with> [<test dir>]

`--name` is a Dart regular expression matched against each test's full name. The name is escaped character by
character (the ECMAScript syntax characters), anchored at its end and put in a negative lookahead after `^`, so only
the test named exactly so is left out. A filter on the prefix alone would also leave out a later test whose name
starts with the same words, and that test would then run in no job at all (SEC-14).

With <test dir>: every `.dart` file under it is read, and the prefix and the full name must each occur exactly once
in all of them together. This catches a second test with exactly the same name in another file: the shards would
leave it out and the pack job, which runs only its own file, would never load it.

Exit 1 if the name is empty, holds a control character, does not start with the prefix (the two values in ci.yml
drifted apart), or the source count is not one. Only the pattern goes to stdout (the workflow captures it); every
message goes to stderr. Standard library only.
"""
import os
import re
import sys

# ECMAScript SyntaxCharacter: the characters that mean something in a Dart (or Python) regular expression.
SYNTAX = set("^$\\.*+?()[]{}|")


def exclude_exactly(name: str) -> str:
    return "^(?!" + "".join("\\" + c if c in SYNTAX else c for c in name) + "$)"


def occurrences(test_dir: str, text: str) -> list:
    """(path, count) of each `.dart` file under test_dir that holds text."""
    found = []
    for root, dirs, names in os.walk(test_dir):
        dirs.sort()
        for n in sorted(names):
            if n.endswith(".dart"):
                path = os.path.join(root, n)
                with open(path, encoding="utf-8", errors="replace") as f:
                    k = f.read().count(text)
                if k:
                    found.append((path.replace("\\", "/"), k))
    return found


def main(argv: list) -> int:
    if len(argv) not in (3, 4):
        print(__doc__.strip().splitlines()[2], file=sys.stderr)
        return 2
    name, prefix = argv[1], argv[2]
    if not name or any(ord(c) < 0x20 for c in name):
        print("exact-name-regex: the test name is empty or holds a control character", file=sys.stderr)
        return 1
    if not prefix or not name.startswith(prefix):
        print("exact-name-regex: the full test name does not start with the prefix", file=sys.stderr)
        return 1
    pattern = exclude_exactly(name)
    # The same pattern read by Python (these escapes mean the same there): it must leave out the name itself and
    # nothing longer, shorter or inside a group.
    r = re.compile(pattern)
    if r.search(name) or not all(r.search(s) for s in (name + " ", name[:-1], "group " + name)):
        print("exact-name-regex: the escaped pattern does not select exactly that name", file=sys.stderr)
        return 1
    if len(argv) == 4:
        if not os.path.isdir(argv[3]):
            print(f"exact-name-regex: no folder {argv[3]!r}", file=sys.stderr)
            return 1
        for label, text in (("prefix", prefix), ("full name", name)):
            found = occurrences(argv[3], text)
            if sum(k for _, k in found) != 1:
                print(
                    f"::error title=only one test may have the every-byte test's name::the {label} occurs "
                    f"{sum(k for _, k in found)} times under {argv[3]} (must be once): {found}",
                    file=sys.stderr,
                )
                return 1
            print(f"exact-name-regex: the {label} occurs once, in {found[0][0]}", file=sys.stderr)
    print(pattern)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

#!/usr/bin/env python3
"""Fails a CI shard if it did not really run what it was given, from the JSON file reporter of `flutter test`.

Usage: python3 tools/ci/assert-tests-ran.py <flutter-test.json> [--files <list file>] [--passed <test name>]
                                            [--printed <text>] [--only <test name>] [--none-start-with <prefix>]

  --files F            every path in F (one per line, as given to flutter test) was loaded as a test suite
  --passed N           a test with exactly the name N ran and passed (not skipped)
  --printed T          some test printed a line containing T
  --only N             exactly one test ran (hidden ones such as "loading ..." and "(setUpAll)" not counted),
                       and its name is exactly N
  --none-start-with P  no test that ran has a name starting with P

`flutter test` already fails on a failing test. This guards the other way a split suite can lose coverage
silently: a filter that matches nothing, a file that was never loaded, a shard switch the test ignores, a second
test with the name the shards leave out. Standard library only; prints what it found; exit 1 on any miss.
"""
import json
import sys


def main(argv: list) -> int:
    if len(argv) < 2:
        print(__doc__.strip().splitlines()[2], file=sys.stderr)
        return 2
    report, files, passed, printed, only, none_start = argv[1], None, [], [], [], []
    i = 2
    while i < len(argv):
        flag = argv[i]
        if i + 1 >= len(argv) or flag not in ("--files", "--passed", "--printed", "--only", "--none-start-with"):
            print(f"assert-tests-ran: bad argument {flag!r}", file=sys.stderr)
            return 2
        value = argv[i + 1]
        if flag == "--files":
            with open(value, encoding="utf-8") as f:
                files = [line.strip() for line in f if line.strip()]
        elif flag == "--passed":
            passed.append(value)
        elif flag == "--printed":
            printed.append(value)
        elif flag == "--only":
            only.append(value)
        else:
            if not value:
                print("assert-tests-ran: --none-start-with needs a prefix", file=sys.stderr)
                return 2
            none_start.append(value)
        i += 2

    suites, tests, messages = [], {}, []
    try:
        with open(report, encoding="utf-8", errors="replace") as f:
            for line in f:
                line = line.strip()
                if not line.startswith("{"):
                    continue
                try:
                    e = json.loads(line)
                except ValueError:
                    continue
                kind = e.get("type")
                if kind == "suite":
                    suites.append((e.get("suite", {}).get("path") or "").replace("\\", "/"))
                elif kind == "testStart":
                    t = e.get("test", {})
                    tests[t.get("id")] = {"name": t.get("name"), "result": None, "skipped": False, "hidden": False}
                elif kind == "testDone":
                    t = tests.get(e.get("testID"))
                    if t is not None:
                        t["result"] = e.get("result")
                        t["skipped"] = bool(e.get("skipped"))
                        t["hidden"] = bool(e.get("hidden"))
                elif kind == "print":
                    messages.append(e.get("message") or "")
    except OSError as exc:
        print(f"assert-tests-ran: cannot read the report ({type(exc).__name__}): the tests did not run", file=sys.stderr)
        return 1

    misses = []
    if files is not None:
        if not files:
            misses.append("the file list is empty")
        for path in files:
            p = path.replace("\\", "/")
            p = p[2:] if p.startswith("./") else p
            if not any(s == p or s.endswith("/" + p) for s in suites):
                misses.append(f"never loaded: {path}")
        print(f"assert-tests-ran: {len(suites)} suites loaded, {len(files)} expected")
    for name in passed:
        ok = [t for t in tests.values() if t["name"] == name and t["result"] == "success" and not t["skipped"]]
        if ok:
            print(f"assert-tests-ran: passed: {name}")
        else:
            misses.append(f"did not run and pass: {name}")
    for text in printed:
        hits = [m for m in messages if text in m]
        if hits:
            print(f"assert-tests-ran: printed: {hits[0][:200]}")
        else:
            misses.append(f"no test printed: {text}")
    # A test whose testDone never came (a crash, a timeout) counts as shown: it ran.
    shown = [t["name"] or "" for t in tests.values() if not t["hidden"]]
    for name in only:
        if shown == [name]:
            print(f"assert-tests-ran: the only test: {name}")
        else:
            others = [n for n in shown if n != name][:5]
            misses.append(f"expected exactly one test, {name}; {len(shown)} ran, others: {others}")
    for prefix in none_start:
        hits = [n for n in shown if n.startswith(prefix)]
        if hits:
            misses.append(
                f"{len(hits)} test(s) start with {prefix!r}; only the one test the shards leave out may (rename): {hits[:5]}"
            )
        else:
            print(f"assert-tests-ran: no test starts with: {prefix}")

    for m in misses:
        print(f"::error title=a test shard did not run what it was given::{m}")
    return 1 if misses else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

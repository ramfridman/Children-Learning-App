#!/usr/bin/env python3
"""Prints where the time of a `flutter test` run went, from its JSON file reporter output.

Usage: python3 tools/ci/test-timings.py <flutter-test.json> [how many rows, default 15]

It lists the slowest test files (from the first event of a file to its last), the slowest single
tests, and any test that started and never finished (what was running when a job was stopped).
The result goes to stdout and, on GitHub Actions, to the job summary. It never fails the job: a
missing or partial file (a cancelled run) gives what it can. Standard library only.
"""
import json
import os
import sys


def main() -> int:
    if len(sys.argv) < 2 or not os.path.isfile(sys.argv[1]):
        print("test-timings: no JSON report to read (the test step did not start, or wrote none)")
        return 0
    top = int(sys.argv[2]) if len(sys.argv) > 2 else 15

    suites = {}  # suite id -> path
    tests = {}  # test id -> {name, suite, start, end, result, hidden}
    last_time = 0
    with open(sys.argv[1], encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.strip()
            if not line.startswith("{"):
                continue
            try:
                e = json.loads(line)
            except ValueError:
                continue  # a cut-off last line in a cancelled run
            t = e.get("time", last_time)
            last_time = max(last_time, t)
            kind = e.get("type")
            if kind == "suite":
                s = e.get("suite", {})
                suites[s.get("id")] = s.get("path") or "?"
            elif kind == "testStart":
                x = e.get("test", {})
                tests[x.get("id")] = {
                    "name": x.get("name", "?"),
                    "suite": x.get("suiteID"),
                    "start": t,
                    "end": None,
                    "result": None,
                }
            elif kind == "testDone":
                x = tests.get(e.get("testID"))
                if x is not None:
                    x["end"] = t
                    x["result"] = "skipped" if e.get("skipped") else e.get("result")

    files = {}
    for x in tests.values():
        path = suites.get(x["suite"], "?")
        end = x["end"] if x["end"] is not None else last_time
        lo, hi = files.get(path, (x["start"], end))
        files[path] = (min(lo, x["start"]), max(hi, end))

    def sec(ms):
        return f"{ms / 1000:8.1f}"

    out = []
    out.append(f"### Flutter tests: where the time went (run length {last_time / 1000:.0f} s)")
    out.append("")
    out.append(f"Slowest {top} test files (first start to last end, seconds; files run side by side):")
    out.append("```")
    for path, (lo, hi) in sorted(files.items(), key=lambda kv: kv[1][0] - kv[1][1])[:top]:
        out.append(f"{sec(hi - lo)}  {path}")
    out.append("```")
    out.append(f"Slowest {top} single tests (seconds; 'loading' rows are compile and load time):")
    out.append("```")
    done = [x for x in tests.values() if x["end"] is not None]
    for x in sorted(done, key=lambda x: x["start"] - x["end"])[:top]:
        out.append(f"{sec(x['end'] - x['start'])}  {suites.get(x['suite'], '?')}: {x['name'][:150]}")
    out.append("```")
    running = [x for x in tests.values() if x["end"] is None]
    if running:
        out.append("Started and never finished (running when the report ends; seconds since start, at least):")
        out.append("```")
        for x in running:
            out.append(f"{sec(last_time - x['start'])}  {suites.get(x['suite'], '?')}: {x['name'][:150]}")
        out.append("```")
    text = "\n".join(out)
    print(text)
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as s:
            s.write(text + "\n")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:  # a report helper must never turn a run red
        print(f"test-timings: could not summarise the report ({type(exc).__name__})")
        sys.exit(0)

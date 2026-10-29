#!/usr/bin/env python3
"""Prints the Flutter test files of one CI shard, one per line, relative to the app folder.

Usage: python3 tools/ci/test-shard.py <test dir> <shard index, 0-based> <number of shards>

Every `*_test.dart` file under <test dir> (the same files `flutter test` finds on its own) goes to exactly one shard.
The split is computed for all shards in every shard and checked before anything is printed: the shards together hold
every file once, none twice, and none is empty. A file not in the table below gets a default weight, so a new test
file is always run. The weights only balance the shards (seconds from the job summary of run 40824493092, files run
four at a time); which files run never depends on them. Standard library only.
"""
import os
import sys

# Seconds per file, first start to last end, from the "Where the test time went" summary of run 40824493092.
# starter_pack_test.dart without its every-byte test (that test runs in its own jobs): about 208 + 50 + 10 s.
WEIGHTS = {
    "starter_pack_test.dart": 270,
    "pack_installer_test.dart": 118,
    "app_flow_test.dart": 102,
    "playthrough_test.dart": 69,
    "golden_screens_test.dart": 67,
    "unit_golden_test.dart": 60,
    "voice_in_test.dart": 59,
    "alerts_flow_test.dart": 46,
    "tutor_lesson_test.dart": 43,
    "lesson_golden_test.dart": 41,
    "companion_everywhere_test.dart": 39,
    "rules_screen_test.dart": 38,
    "push_test.dart": 37,
    "lesson_flow_test.dart": 36,
    "zip_store_test.dart": 33,
}
DEFAULT_WEIGHT = 8


def all_test_files(test_dir: str) -> list:
    found = []
    for root, dirs, files in os.walk(test_dir):
        dirs.sort()
        for name in files:
            if name.endswith("_test.dart"):
                found.append(os.path.join(root, name).replace(os.sep, "/"))
    return sorted(found)


def split(files: list, shards: int) -> list:
    """Longest first, each file to the lightest shard so far (ties: the lower index). Deterministic."""
    def weight(path: str) -> int:
        return WEIGHTS.get(path.rsplit("/", 1)[-1], DEFAULT_WEIGHT)

    loads = [0] * shards
    parts = [[] for _ in range(shards)]
    for path in sorted(files, key=lambda p: (-weight(p), p)):
        k = min(range(shards), key=lambda i: (loads[i], i))
        parts[k].append(path)
        loads[k] += weight(path)
    return [sorted(p) for p in parts]


def main() -> int:
    if len(sys.argv) != 4:
        print(__doc__.strip().splitlines()[2], file=sys.stderr)
        return 2
    test_dir, index, shards = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
    if shards < 1 or not 0 <= index < shards:
        print(f"test-shard: shard {index} of {shards} does not exist", file=sys.stderr)
        return 2
    files = all_test_files(test_dir)
    if not files:
        print(f"test-shard: no *_test.dart files under {test_dir}", file=sys.stderr)
        return 1
    parts = split(files, shards)
    flat = [f for p in parts for f in p]
    if sorted(flat) != files or len(set(flat)) != len(flat):
        print("test-shard: the shards do not hold every file exactly once", file=sys.stderr)
        return 1
    if any(not p for p in parts):
        print(f"test-shard: {shards} shards for {len(files)} files leaves a shard empty", file=sys.stderr)
        return 1
    for k, p in enumerate(parts):
        mark = "  <- this job" if k == index else ""
        print(f"test-shard: shard {k}: {len(p)} files{mark}", file=sys.stderr)
    print("\n".join(parts[index]))
    return 0


if __name__ == "__main__":
    sys.exit(main())

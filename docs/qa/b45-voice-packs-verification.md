# QA verification: B-45 voice packs split per narrator and the lazy voice bank

2026-11-02, qa-engineer. Worktree `D:\nitznutz-vsplit`, branch `b45-voice-pack-split` (commits fbe8f23, ccd84cb on 78f0887), uncommitted QA tests added. Plan: `docs/audio/b45-voicing-plan.md` section 4.4, section 7, decision 6; `docs/PLAN.md` (voice_gen paragraph, Content packs "File").

**Verdict: PASS with three minor findings (QA-B45-1 to -3) and a list of device-only checks. No blocker, no major.**

## What ran

| Command (in `app/`) | Result |
|---|---|
| `flutter analyze` | No issues found (after removing unused imports in my two new files) |
| `dart format --output=none --set-exit-if-changed .` | 379 files, 0 changed |
| `flutter test` (whole suite, once, alone) | 3,184 passed, 4 skipped, 1 failed: only the known `starter_pack_test` "the pack was built from the sources in content/starter and nothing else" |
| `dart run tool/voice_gen.dart plan nitzi` (free) | 16 packs for nitzi (3,989 lines, 174,559 characters), 1 pack of 9 lines for each friend; the 2 `mathb01 h3` lines still wait for approval, as the plan says |
| New `test/qa_b45_voice_packs_end_to_end_test.dart` | 11 passed (about 1 minute) |
| New `test/qa_b45_lesson_prefetch_test.dart` | 2 passed; mutation check below |

Not run: `deno task check` (nothing under `supabase/` or `testvectors/` changed), `voice_gen pack` (blocked for agents by the hook; the re-pack is tested through the Dart functions with mock clips), anything that touches ElevenLabs or its key. No real key: a throw-away key from `newTestKey()` in a temp folder. The two new test files are the only untracked files; no source file is changed (I removed the prefetch call for the mutation check and restored it; `git status` shows only the two new tests).

## Criteria and the test that proves each

| Criterion | Proof |
|---|---|
| A narrator is 16 packs (shared + 15 land-and-band parts), a friend 1 | e2e test 2: built from all **3,991** real ids (starter content + core lines) with mock clips; `nitzi.length == 16`, `gali.length == 1`, file names `voice-nitzi-2.0.0`, `voice-nitzi-part-<group>-2.0.0` |
| Every pack passes `verifyPack` under `ZipLimits`, at most 40 MiB and 3,000 files | e2e test 2: each pack `verifyPack`ed with the test public key; entries < 3,000 and < `ZipLimits.maxEntries`; bytes <= 40 MiB and < `ZipLimits.maxTotalBytes`; a second key is refused |
| Every planned id is in exactly one pack, in the pack its group names | e2e test 2: 3,991 ids seen, none twice, set equal to the planned set, pack id matches `voiceGroupOf` |
| Installed with the real installer (`PackInstaller`, on-disk folder, in-memory registry) | e2e group "installed": 17 packs installed once and read by several tests |
| Index knows all lines at start; only the shared pack is resident | e2e test 3: `bank.length == 3991`, `residentPacks == ['voice-nitzi']` |
| A line from each of the 15 parts and a core line, with that line's own sound and mouth cues | e2e test 4 (the clip bytes carry `nitzi|<text>`, texts unique per id) |
| Eviction after three lands: the first goes, the shared pack stays, going back reloads; 5 parts asked at once end within the bound (pinned + 2) | e2e test 5 |
| Lesson prefetch loads only the parts of the lesson's lines, then the director plays with nothing to wait for | e2e test 6 (a real `activity.b.numb03.*` document) |
| Friend: own line in its own voice, a borrowed line in the narrator's after its part loads, a line both have stays the friend's, the friend's prefetch reaches the narrator's pack | e2e test 7 |
| A tampered part pack (one byte appended to a sound file) is refused on load, its lines are silent with no exception, the shared pack and other lands still play, the bad pack is not read again | e2e test 8 |
| Same for a friend whose narrator part is tampered; the friend's own lines still play | e2e test 9 |
| A deleted part folder is a missing clip | e2e test 10 |
| Size guard: 440 real ids at 100 KiB a clip (43 MiB) fail the build naming the pack, saying nothing was signed and giving `--max-lines`; clips are kept; a free re-pack with `maxLines: 200` builds packs that all verify, ids once | e2e test 11 |
| `LessonScreen` calls `prefetch` (the developer's open gap) | `qa_b45_lesson_prefetch_test.dart` test 1: real `LessonScreen` on the real starter pack with a spy director: exactly one `prefetch`, with exactly the `vo:` ids of all the lesson's activities, in order. Test 2: with a lazy narrator bank the part pack is loaded once and the first question is played. |

Mutation check: with the `_director.prefetch(...)` call removed from `lesson_screen.dart`, test 1 fails (`Expected: an object with length of <1>  Actual: []`). Test 2 still passes without the call, because `say` loads the pack on demand; it proves the end to end result, test 1 proves the call.

The developer's own 4 files (`voice_lazy_test`, `voice_multi_pack_test`, `voice_pack_build_test`, `voice_packs_test`) cover the same ground with small fixtures; I did not repeat their unit cases (director drop-when-replaced, relevant(), sayNext queue, determinism of the re-pack, no-synth source rule).

## Findings (hand-offs)

- **QA-B45-1 (minor until measured on the phone; may become major, app-developer).** `lib/content/pack_installer.dart:229-239` (`load`): reads every file with `readAsBytesSync` and `verifyEntries` hashes them (pure Dart SHA-256) and checks the signature, all on the UI isolate. Measured here (desktop, debug JIT, my scratch test, deleted): a 440-line pack of 26.7 MiB loads in 430 to 460 ms. A lesson open prefetches up to two parts, a land change loads one. On the Samsung in release this may be shorter or longer; if it is over about 100 ms it will drop frames at lesson open. Repro: install the 16 mock packs, call `bank.prefetch` of a lesson with two parts, watch the frame timeline. Suggestion: run `load` (read + verify) in a `compute`/`Isolate.run`, or measure first.
- **QA-B45-2 (minor, app-developer).** `lib/voice/voice_bank.dart:136,145`: a pack that fails once (also a transient read error, not only tampering) is given up for the life of the bank; its lines stay silent until the guide changes or the app restarts. This is the spec ("behaves like a missing clip"), but one transient error silences a whole land. Optional: allow one retry after some minutes, or on the next lesson open.
- **QA-B45-3 (minor, voice-and-sound-director / app-developer, wording of docs).** `docs/PLAN.md` and the plan say memory is "the shared pack plus two parts (about 75 MiB at 60 KiB, at most 120 MiB)". That counts the clip bytes only: `load` holds the file map and the `VerifiedPack` (and the player gets a copy per play), and while a third part is read the old one is still counted; the real peak is not measured. Not wrong code; the claim needs the device number (below).

No defect found in: layout (a pure function, ids unique, no id lost), signing and verification, install, index from manifests checked against the recorded hash, eviction (LRU, pinned never pushed out), friend fallback, silent fallback for a bad pack, the size guard and the free re-pack.

## Only a device check on the Samsung can confirm

1. First-line gap: open a lesson in each land and band right after opening the app; time from tap to the first spoken question (target: no audible gap beyond what a lesson open already has). Repeat for the replay button after the child has visited three lands (the pack must reload).
2. Frame drops at lesson open and when a part loads (QA-B45-1): Flutter performance overlay, or `adb shell dumpsys gfxinfo`.
3. Memory: `adb shell dumpsys meminfo <package>` after visiting four lands, with Hero-son or Nitzi as guide; expect the shared pack plus two parts, compare to the 75 to 120 MiB claim. Also with a friend (two banks: the friend's one pack and the narrator's).
4. Install time and disk: 16 packs of one narrator (about 100 to 240 MB real, not the mock sizes) installed from the real download, and the install of a second narrator. The installer's own on-disk checks were only run with mock sizes here.
5. A real mid-install state: only the shared pack and some parts installed (download interrupted); the lines of a missing part must be silent with no crash.
6. Sound itself: no clip or cue of a real narrator was heard (mock clips only); the mouth cues on the real clips.

# Signing the starter pack 0.11.0 and the first language packs (eng, heb, rus 0.1.0)

Only you can do this: the pack-signing key stays on your PC (`%USERPROFILE%\nitznutz-secrets\pack-signing.key`, copy in 1Password). Claude never reads it. The tool finds the key at that path by itself; no step prints it.

What is signed: `starter-0.11.0.nnpack` (sources in `content/starter`, `version` 0.11.0) and `lang-eng-0.1.0.nnpack`, `lang-heb-0.1.0.nnpack`, `lang-rus-0.1.0.nnpack` (first signing; sources in `content/languages/<course>`, `pack.version` 0.1.0). All four go into `app\assets\packs`, which `pubspec.yaml` bundles as a folder, so nothing else needs listing. The app finds the language packs by their file names.

All commands are PowerShell 5.1 and start from the app folder.

1. Go to the app folder and check you are on the right branch.

```powershell
cd D:\nitznutz-release\app
git branch --show-current
```

You should see `content-release`.

2. Check the sources: neither command may change a file.

```powershell
python ..\tools\regen_content.py
git -C D:\nitznutz-release status --short
python ..\tools\lang_pack.py all --check
```

`git status` should list only the changes Claude made for this release (no `content/` file other than `content/starter/pack.json`). The last command ends with `eng: 405 files`, `heb: 407 files`, `rus: 759 files` and no error.

3. Build and sign the starter pack.

```powershell
dart run tool/pack_builder.dart build ..\content\starter --out assets\packs
```

You should see `Built assets\packs\starter-0.11.0.nnpack: ... bytes, manifest sha256 ...`.

4. Remove the old starter file (the build does not remove it; the language build removes older language packs by itself).

```powershell
if ($?) { Remove-Item assets\packs\starter-0.10.0.nnpack }
```

5. Build and sign the three language packs.

```powershell
dart run tool/pack_builder.dart build-language all
```

You should see three `Built assets/packs/lang-<course>-0.1.0.nnpack` lines (eng, heb, rus).

6. Verify all four against the public key built into the app.

```powershell
foreach ($f in 'starter-0.11.0','lang-eng-0.1.0','lang-heb-0.1.0','lang-rus-0.1.0') { dart run tool/pack_builder.dart verify "assets\packs\$f.nnpack" }
```

You should see four lines `OK: <id> <version> is genuine (manifest sha256 ...)`.

7. Regenerate the shared publish vector from the new starter (the gateway tests read it), then run the pack tests.

```powershell
$env:NN_UPDATE_VECTORS = '1'
flutter test test/publish_test.dart
Remove-Item Env:\NN_UPDATE_VECTORS
flutter test test/starter_pack_test.dart test/language_packs_build_test.dart test/bundled_language_packs_test.dart
```

All should end with `All tests passed!`. (`testvectors\publish-starter.json` changes: Claude commits it with the packs.)

8. Check that the folder holds exactly these five files, and no key is in the repo.

```powershell
Get-ChildItem assets\packs | Select-Object Name, Length
git -C D:\nitznutz-release status --short
```

You should see `starter-0.11.0.nnpack` and the three `lang-*-0.1.0.nnpack` (no `starter-0.10.0`), plus the vector file in git status.

9. Tell Claude "signed". Claude then runs the whole test suite, commits the `.nnpack` files and the vector, and the usual CI runs (six jobs).

## What happens on the server (nothing yet)

- The starter pack is bundled in the app, so this release needs no deploy. Publishing 0.11.0 to the server (`pack_builder publish starter --dry-run`, then for real, needs `NITZNUTZ_PUBLISH_SECRET`) is a separate step, only needed when the tutor must know the new items.
- If you do publish it: PROGRESS and PLAN say a pack bump needs the tutor prewarm `carry` step on the server (the tutor's cache is keyed to the pack version). Claude has not run or checked it for this release; it is part of that later publish step, to be planned with the dry run first (and any paid voicing stays yours).
- The language packs (`lang-*`) are bundled only; they are not published by this release.

## Decisions for you

- Whether to publish starter 0.11.0 to the server now, or only ship it inside the next build (the app works either way).
- The 0.10.0 starter stays in git history only; nothing else needs it.

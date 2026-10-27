# M4: builds the packs that put the family characters and free test voices on a phone, and (with -Push) copies
# them into the app's incoming folder so the dev page can install them. Run from the repository root:
#
#   powershell -ExecutionPolicy Bypass -File tools\make-m4-device-packs.ps1 [-Push]
#
# It builds, into out\m4-device\:
#   char-<id>-1.0.0.nnpack   one per family character in design\family-pack (signed with your pack-signing key)
#   voice-<id>-1.0.0.nnpack  a free test voice (a tone of a different pitch per character) for Nitzi and each of them
# Nothing here calls ElevenLabs and nothing costs money. The family characters are personal packs: they are
# never bundled in the app, only installed on your own phones.

param([switch]$Push)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$app = Join-Path $root 'app'
$out = Join-Path $root 'out\m4-device'
New-Item -ItemType Directory -Force $out | Out-Null
Remove-Item (Join-Path $out '*.nnpack') -Force -ErrorAction SilentlyContinue

Push-Location $app
try {
  $ids = @('nitzi')
  foreach ($dir in Get-ChildItem (Join-Path $root 'design\family-pack') -Directory) {
    dart run tool/pack_builder.dart build-character $dir.FullName --out $out
    if ($LASTEXITCODE -ne 0) { throw "build-character failed for $($dir.Name)" }
    $ids += $dir.Name
  }
  foreach ($id in $ids) {
    $work = Join-Path $env:USERPROFILE "nitznutz-voice\$id"
    dart run tool/voice_gen.dart mock $id --out $work
    if ($LASTEXITCODE -ne 0) { throw "voice_gen mock failed for $id" }
    Copy-Item (Join-Path $work 'voice-*.nnpack') $out -Force
  }
} finally { Pop-Location }

Get-ChildItem $out -Filter *.nnpack | ForEach-Object { '{0}  {1:N0} bytes' -f $_.Name, $_.Length }

if ($Push) {
  $env:Path += ";$env:LOCALAPPDATA\Android\Sdk\platform-tools"
  $pkg = 'app.nitznutz.nitznutz.dev'
  adb shell run-as $pkg mkdir -p no_backup/incoming
  foreach ($f in Get-ChildItem $out -Filter *.nnpack) {
    adb push $f.FullName "/data/local/tmp/$($f.Name)" | Out-Null
    adb shell run-as $pkg cp "/data/local/tmp/$($f.Name)" "no_backup/incoming/$($f.Name)"
    adb shell rm "/data/local/tmp/$($f.Name)"
  }
  'Pushed. On the phone: Parents > dev harness > Install .nnpack files from the incoming folder.'
}

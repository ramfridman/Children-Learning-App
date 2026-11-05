# M5 and L3: measures the speech model and the matcher on recordings, on this PC. From the repository root:
#
#   powershell -ExecutionPolicy Bypass -File tools\run-asr-eval.ps1 <folder with .wav files and labels.csv> [-Course heb|eng|rus] [-Speakers <speakers.csv>] [-Mode biased|open] [-Sweep] [-Csv <result file>]
#
# Hebrew (the default, M5): app\tool\asr_eval.dart, whose labels.csv is "file,type,intended,options" (numbers, colours, words).
# English and Russian (L3): app\tool\say_eval.dart, which counts "heard" and "confident when it should not be" per age band against the
# release gate of docs/milestones/L3.md section 4; its labels.csv is "file,said,forms,foils" and its speakers file "speaker,age".
#
# The first run downloads the model (tools\make-m5-model.ps1 or tools\make-asr-models.ps1 do that) and the x64 Windows libraries of
# sherpa-onnx v2.0.0 (the pub.dev package carries only the ARM ones), checks both against pinned SHA-256 values, and then runs the tool.
# Nothing is uploaded; the recordings stay in your folder.
param(
  [Parameter(Mandatory = $true)][string]$Folder,
  [ValidateSet('heb', 'eng', 'rus')][string]$Course = 'heb',
  [string]$Csv,
  [string]$Speakers,
  [ValidateSet('biased', 'open')][string]$Mode,
  [switch]$Sweep
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$libRoot = Join-Path $root 'out\sherpa-win-x64'
$archive = Join-Path $libRoot 'sherpa-onnx-v2.0.0-win-x64-shared-MD-Release-lib.tar.bz2'
$expected = '2b7f798a6586cc8cf37e226a82cd7f9727d7fe5ae73ef6244edbee766279a386'
$libDir = Join-Path $libRoot 'sherpa-onnx-v2.0.0-win-x64-shared-MD-Release-lib\lib'

if (-not (Test-Path (Join-Path $libDir 'sherpa-onnx-c-api.dll'))) {
  New-Item -ItemType Directory -Force $libRoot | Out-Null
  if (-not (Test-Path $archive)) {
    gh release download v2.0.0 -R k2-fsa/sherpa-onnx -p 'sherpa-onnx-v2.0.0-win-x64-shared-MD-Release-lib.tar.bz2' -D $libRoot
  }
  $actual = (Get-FileHash $archive -Algorithm SHA256).Hash.ToLower()
  if ($actual -ne $expected) { throw "The sherpa-onnx library archive is not the one this script trusts ($actual)." }
  tar -xjf $archive -C $libRoot
}
$model = if ($Course -eq 'heb') { Join-Path $root 'out\speech-model' } else { Join-Path $root "out\asr-$Course" }
if (-not (Test-Path (Join-Path $model 'encoder.int8.onnx'))) {
  if ($Course -eq 'heb') { & (Join-Path $PSScriptRoot 'make-m5-model.ps1') } else { & (Join-Path $PSScriptRoot 'make-asr-models.ps1') -Course $Course }
}

$env:Path = "$libDir;$env:Path"
$folderPath = (Resolve-Path $Folder).Path
Push-Location (Join-Path $root 'app')
try {
  if ($Course -eq 'heb') {
    $argsList = @('run', 'tool/asr_eval.dart', $folderPath, '--model', $model, '--lib', $libDir)
    if ($Csv) { $argsList += @('--csv', $Csv) }
  } else {
    $argsList = @('run', 'tool/say_eval.dart', $folderPath, '--course', $Course, '--model', $model, '--lib', $libDir)
    if ($Csv) { $argsList += @('--csv', $Csv) }
    if ($Speakers) { $argsList += @('--speakers', (Resolve-Path $Speakers).Path) }
    if ($Mode) { $argsList += @('--mode', $Mode) }
    if ($Sweep) { $argsList += '--sweep' }
  }
  dart @argsList
} finally { Pop-Location }

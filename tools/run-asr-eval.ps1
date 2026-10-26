# M5: measures the speech model and the answer matcher on recordings, on this PC. From the repository root:
#
#   powershell -ExecutionPolicy Bypass -File tools\run-asr-eval.ps1 <folder with .wav files and labels.csv>
#
# The first run downloads the model (tools\make-m5-model.ps1 does that) and the x64 Windows libraries of sherpa-onnx v2.0.0
# (the pub.dev package carries only the ARM ones), checks both against pinned SHA-256 values, and then runs
# app\tool\asr_eval.dart. Nothing is uploaded; the recordings stay in your folder.
param([Parameter(Mandatory = $true)][string]$Folder, [string]$Csv)

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
$model = Join-Path $root 'out\speech-model'
if (-not (Test-Path (Join-Path $model 'encoder.int8.onnx'))) { & (Join-Path $PSScriptRoot 'make-m5-model.ps1') }

$env:Path = "$libDir;$env:Path"
$folderPath = (Resolve-Path $Folder).Path
Push-Location (Join-Path $root 'app')
try {
  $argsList = @('run', 'tool/asr_eval.dart', $folderPath, '--model', $model, '--lib', $libDir)
  if ($Csv) { $argsList += @('--csv', $Csv) }
  dart @argsList
} finally { Pop-Location }

# M5: gets the speech model (ivrit.ai zipformer2-66m-streaming-he, CC-BY-4.0, about 72 MB) from Hugging Face at a pinned
# revision, checks every file against the SHA-256 written in the app (app\lib\speech\model_spec.dart), and with -Push puts
# the files on the phone, in the app's private folder. From the repository root:
#
#   powershell -ExecutionPolicy Bypass -File tools\make-m5-model.ps1 [-Push]
#
# A file that does not match is deleted and the script stops. The app checks the same hashes again before it loads them.
param([switch]$Push)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$out = Join-Path $root 'out\speech-model'
$rev = 'ee769a2a13b887f91572eec349458bfb0fe79e7a'
$base = "https://huggingface.co/ivrit-ai/zipformer2-66m-streaming-he/resolve/$rev/sherpa-onnx"
$files = [ordered]@{
  'encoder.int8.onnx' = '6c6febcb74a09435315a1d872a6539f6e7fc2c333533f14c74edc0e85c49ffcd'
  'decoder.int8.onnx' = 'feb03e7c8aa761593a9284a6fa1e91259be3702de75f630062256c1a59c5a906'
  'joiner.int8.onnx'  = '1d2c6d8e6dabc5eb52de52e95718e9bdfbffbfe7ead3808fb5ffd74e83bd9cae'
  'tokens.txt'        = 'e4ebb5e72a6aeef47437a55fa2308ebbedb7c51c557de7a89bf965c23ea9af4a'
}
New-Item -ItemType Directory -Force $out | Out-Null
foreach ($name in $files.Keys) {
  $path = Join-Path $out $name
  if (-not (Test-Path $path)) { curl.exe -sL -o $path "$base/$name" }
  $hash = (Get-FileHash $path -Algorithm SHA256).Hash.ToLower()
  if ($hash -ne $files[$name]) { Remove-Item $path -Force; throw "$name does not match its pinned SHA-256; it was deleted." }
  '{0}  ok  {1:N0} bytes' -f $name, (Get-Item $path).Length
}

if ($Push) {
  $env:Path += ";$env:LOCALAPPDATA\Android\Sdk\platform-tools"
  $pkg = 'app.nitznutz.nitznutz.dev'
  $dir = 'no_backup/speech-model-he-1'
  adb shell run-as $pkg mkdir -p $dir
  foreach ($name in $files.Keys) {
    adb push (Join-Path $out $name) "/data/local/tmp/$name" | Out-Null
    adb shell run-as $pkg cp "/data/local/tmp/$name" "$dir/$name"
    adb shell rm "/data/local/tmp/$name"
  }
  'Pushed. On the phone: Parents > Voice answers.'
}

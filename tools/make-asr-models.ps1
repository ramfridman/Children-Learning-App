# L3: gets the English and Russian speech models (docs/milestones/L3.md section 7.1) from Hugging Face at pinned revisions, checks every
# file against the SHA-256 written in the app (app\lib\speech\model_spec.dart), makes the word-piece list the hotwords need
# (bpe.vocab, from bpe.model, by tools\bpe_vocab.py), and with -Push puts the files on the phone, in the app's private folder.
# From the repository root:
#
#   powershell -ExecutionPolicy Bypass -File tools\make-asr-models.ps1 -Course eng [-Push]
#   powershell -ExecutionPolicy Bypass -File tools\make-asr-models.ps1 -Course rus [-Push]
#
# The Hebrew model has its own script (tools\make-m5-model.ps1). A file that does not match is deleted and the script stops. The app
# checks the same hashes again before it loads a model. Nothing is uploaded. Until the owner chooses a host for the models (R2), this
# cable route is how a model comes onto a phone, and app\network_hosts.json is unchanged.
param([Parameter(Mandatory = $true)][ValidateSet('eng', 'rus')][string]$Course, [switch]$Push)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$out = Join-Path $root "out\asr-$Course"

# folder name on the phone, source repository and revision, then for each file: its name in the app, the name at the source (with a
# path when it comes from another repository), and the SHA-256 the app pins.
$sets = @{
  eng = @{
    folder = 'speech-model-eng-1'
    files  = [ordered]@{
      'encoder.int8.onnx' = @('csukuangfj/sherpa-onnx-streaming-zipformer-en-20M-2023-02-17', 'd42f2d9f7ca24806fb667456a18a9f1b60f70d16', 'encoder-epoch-99-avg-1.int8.onnx', '3810755ce7c3ab26b42a8bcf39d191308fa27fb0f53358823ba46141d03b7eb3')
      'decoder.int8.onnx' = @('csukuangfj/sherpa-onnx-streaming-zipformer-en-20M-2023-02-17', 'd42f2d9f7ca24806fb667456a18a9f1b60f70d16', 'decoder-epoch-99-avg-1.int8.onnx', '21e2a2acd961b3ac72f55be2f10f1a285e1b0b0ba010d7c0b6eab141411b163c')
      'joiner.int8.onnx'  = @('csukuangfj/sherpa-onnx-streaming-zipformer-en-20M-2023-02-17', 'd42f2d9f7ca24806fb667456a18a9f1b60f70d16', 'joiner-epoch-99-avg-1.int8.onnx', 'e085d73b593cf9b0707f370dbd656d58327d3fe36d80d849202ef81df02cb01e')
      'tokens.txt'        = @('csukuangfj/sherpa-onnx-streaming-zipformer-en-20M-2023-02-17', 'd42f2d9f7ca24806fb667456a18a9f1b60f70d16', 'tokens.txt', '49e3c2646595fd907228b3c6787069658f67b17377c60aeb8619c4551b2316fb')
    }
    bpe    = @('desh2608/icefall-asr-librispeech-pruned-transducer-stateless7-streaming-small', 'be162ecc09bade73063a671fad9d18220149d25b', 'data/lang_bpe_500/bpe.model', 'c53433de083c4a6ad12d034550ef22de68cec62c4f58932a7b6b8b2f1e743fa5')
    vocab  = 'f191a4935f668fa8cd8e607bcd378404f948321cd3134a5ea13d324ba921673d'
  }
  rus = @{
    folder = 'speech-model-rus-1'
    files  = [ordered]@{
      'encoder.int8.onnx' = @('csukuangfj/sherpa-onnx-streaming-zipformer-small-ru-vosk-int8-2025-08-16', '31fa603e4f31279c6e1f7600fed13dc4312663ab', 'encoder.int8.onnx', 'e0db705e94ec35d803b1df4f40cda23d064e1142977c80ab288430b109777a9d')
      'decoder.onnx'      = @('csukuangfj/sherpa-onnx-streaming-zipformer-small-ru-vosk-int8-2025-08-16', '31fa603e4f31279c6e1f7600fed13dc4312663ab', 'decoder.onnx', '89b3088a9e20e1ef7f2e85ce1a3478afe6a9c4ac57369cabcc4beb8e95328ea0')
      'joiner.int8.onnx'  = @('csukuangfj/sherpa-onnx-streaming-zipformer-small-ru-vosk-int8-2025-08-16', '31fa603e4f31279c6e1f7600fed13dc4312663ab', 'joiner.int8.onnx', 'b55784b071ab7512eab4c7c44e4f5478284ef33c83562cc6a249b972515a31e5')
      'tokens.txt'        = @('csukuangfj/sherpa-onnx-streaming-zipformer-small-ru-vosk-int8-2025-08-16', '31fa603e4f31279c6e1f7600fed13dc4312663ab', 'tokens.txt', '93bbbc0bae6b78c0bbb743d4aa9fded3bb5ff3aac5f0200e3a769a5a05e0fdf6')
    }
    bpe    = @('csukuangfj/sherpa-onnx-streaming-zipformer-small-ru-vosk-int8-2025-08-16', '31fa603e4f31279c6e1f7600fed13dc4312663ab', 'bpe.model', 'c7a756aeb3550417d6b2ed3efde9a7aa3eea54787d4eac011e9cce6090c9c64a')
    vocab  = '52649881bb41fafe4257c74d77a85320524494a9d8c48e93d4aaa216cc45113d'
  }
}
$set = $sets[$Course]
New-Item -ItemType Directory -Force $out | Out-Null

function Get-Checked($path, $url, $expected) {
  if (-not (Test-Path $path)) { curl.exe -sL --fail -o $path $url }
  $hash = (Get-FileHash $path -Algorithm SHA256).Hash.ToLower()
  if ($hash -ne $expected) { Remove-Item $path -Force; throw "$path does not match its pinned SHA-256; it was deleted." }
  '{0}  ok  {1:N0} bytes' -f (Split-Path $path -Leaf), (Get-Item $path).Length
}

foreach ($name in $set.files.Keys) {
  $f = $set.files[$name]
  Get-Checked (Join-Path $out $name) "https://huggingface.co/$($f[0])/resolve/$($f[1])/$($f[2])" $f[3]
}
$b = $set.bpe
$model = Join-Path $out 'bpe.model'
Get-Checked $model "https://huggingface.co/$($b[0])/resolve/$($b[1])/$($b[2])" $b[3]
$vocab = Join-Path $out 'bpe.vocab'
python -I (Join-Path $PSScriptRoot 'bpe_vocab.py') $model $vocab | Out-Null
$hash = (Get-FileHash $vocab -Algorithm SHA256).Hash.ToLower()
if ($hash -ne $set.vocab) { Remove-Item $vocab -Force; throw 'bpe.vocab does not match its pinned SHA-256; it was deleted.' }
'bpe.vocab  ok  {0:N0} bytes (made from bpe.model)' -f (Get-Item $vocab).Length
Remove-Item $model -Force

if ($Push) {
  $env:Path += ";$env:LOCALAPPDATA\Android\Sdk\platform-tools"
  $pkg = 'app.nitznutz.nitznutz.dev'
  $dir = "no_backup/$($set.folder)"
  adb shell run-as $pkg mkdir -p $dir
  $names = @($set.files.Keys) + 'bpe.vocab'
  foreach ($name in $names) {
    adb push (Join-Path $out $name) "/data/local/tmp/$name" | Out-Null
    adb shell run-as $pkg cp "/data/local/tmp/$name" "$dir/$name"
    adb shell rm "/data/local/tmp/$name"
  }
  'Pushed. On the phone: Parents > the language > Voice answers.'
}

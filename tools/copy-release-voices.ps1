# Copies the owner's finished voice packs into the app's assets, so a release build carries Nitzi's voice.
# Run from the repository root, in the owner's own PowerShell, before `flutter build`:
#   powershell -ExecutionPolicy Bypass -File tools\copy-release-voices.ps1
#   powershell -ExecutionPolicy Bypass -File tools\copy-release-voices.ps1 -NoLanguages   (Nitzi only)
#   powershell -ExecutionPolicy Bypass -File tools\copy-release-voices.ps1 -Clean         (remove them again)
#
# What it does (it reads files and copies files; it needs no key, sends nothing and builds nothing):
#   1. Takes the packs voice-nitzi-<version>.nnpack and voice-nitzi-<N>-<version>.nnpack (N from 2 to 9) of the NEWEST version
#      found in <Source>\nitzi\ (the folder `voice_gen pack nitzi` writes to; default ~\nitznutz-voice) and copies them to
#      app\assets\characters\. Only Nitzi: Hero-son and the seven friends are personal characters and are never bundled
#      (CLAUDE.md), so this script has no way to copy them.
#   2. Unless -NoLanguages: the packs voice-lang-<eng|heb|rus>-<version>.nnpack of <Source>\lang-<course>\ (the folders
#      `voice_gen generate-lang` and `pack` write to) go to app\assets\packs\; the course packs play their lines in them.
#   3. Removes older copies of the same packs from the assets first, so one version of each is bundled.
#   4. Refuses a pack over 64 MiB, or a voice over 128 MiB in all (the limits of the app's pack reader and voice bank).
# The copies are ignored by Git (.gitignore): they are about 98 MiB and the repository is public. Run it again after every new
# voice build; a build without them still works, Nitzi is then text only until the voice packs are installed some other way.
param(
  [string]$Source = (Join-Path $env:USERPROFILE 'nitznutz-voice'),
  [switch]$NoLanguages,
  [switch]$Clean
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = (& git rev-parse --show-toplevel).Trim()
if (-not $repoRoot) { throw 'Run this script inside the repository.' }
$characters = Join-Path $repoRoot 'app\assets\characters'
$packs = Join-Path $repoRoot 'app\assets\packs'
$maxPack = 64MB
$maxVoice = 128MB

# The only characters whose voice may be bundled: the ones whose character pack says distribution: bundled.
$bundled = @('nitzi')
$courses = @('eng', 'heb', 'rus')

function Remove-Voices($folder, $pattern) {
  Get-ChildItem -Path $folder -Filter $pattern -File -ErrorAction SilentlyContinue | ForEach-Object {
    Remove-Item -LiteralPath $_.FullName -Force
    Write-Host "removed $($_.Name)"
  }
}

if ($Clean) {
  foreach ($id in $bundled) { Remove-Voices $characters "voice-$id*.nnpack" }
  Remove-Voices $packs 'voice-lang-*.nnpack'
  return
}

# Newest version of the packs named <prefix>[-N]-<version>.nnpack in a folder, as the files of that version.
function Get-Newest($folder, $prefix) {
  if (-not (Test-Path -LiteralPath $folder)) { throw "No folder $folder. Run `dart run tool/voice_gen.dart pack ...` first." }
  $pattern = '^' + [regex]::Escape($prefix) + '(?:-([2-9]))?-(\d{1,3}\.\d{1,3}\.\d{1,3})\.nnpack$'
  $found = @()
  foreach ($f in Get-ChildItem -LiteralPath $folder -Filter "$prefix*.nnpack" -File) {
    if ($f.Name -match $pattern) { $found += [pscustomobject]@{ File = $f; Version = [version]$Matches[2] } }
  }
  if ($found.Count -eq 0) { throw "No $prefix pack in $folder." }
  $newest = ($found | Sort-Object Version -Descending | Select-Object -First 1).Version
  return @($found | Where-Object { $_.Version -eq $newest } | ForEach-Object { $_.File })
}

$total = 0
$plan = @()
foreach ($id in $bundled) {
  $files = Get-Newest (Join-Path $Source $id) "voice-$id"
  foreach ($f in $files) {
    if ($f.Length -gt $maxPack) { throw "$($f.Name) is over 64 MiB: the app refuses it." }
    $total += $f.Length
    $plan += [pscustomobject]@{ From = $f; To = $characters; Remove = "voice-$id*.nnpack" }
  }
}
if ($total -gt $maxVoice) { throw 'The voice is over 128 MiB: the app would leave a part out.' }
if (-not $NoLanguages) {
  foreach ($c in $courses) {
    $files = Get-Newest (Join-Path $Source "lang-$c") "voice-lang-$c"
    foreach ($f in $files) {
      if ($f.Length -gt $maxPack) { throw "$($f.Name) is over 64 MiB: the app refuses it." }
      $plan += [pscustomobject]@{ From = $f; To = $packs; Remove = "voice-lang-$c*.nnpack" }
    }
  }
}

# Old copies out, new copies in.
foreach ($item in ($plan | Select-Object -Property To, Remove -Unique)) { Remove-Voices $item.To $item.Remove }
foreach ($item in $plan) {
  Copy-Item -LiteralPath $item.From.FullName -Destination $item.To -Force
  '{0,-34} {1,8:N1} MiB  ->  {2}' -f $item.From.Name, ($item.From.Length / 1MB), $item.To
}
Write-Host ('Nitzi voice: {0:N1} MiB of 128. Not committed (.gitignore). Now build the app.' -f ($total / 1MB))

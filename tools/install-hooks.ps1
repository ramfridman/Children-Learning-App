# Installs the pinned gitleaks release and turns on the repository's pre-commit hook.
# Run from the repository root:
#   powershell -ExecutionPolicy Bypass -File tools\install-hooks.ps1
#
# What it does:
#   1. Reads the pinned gitleaks version and SHA-256 from tools\ci\tool-versions.env.
#   2. Downloads the official Windows release and refuses to continue if the checksum differs.
#   3. Puts gitleaks.exe in tools\bin\ (ignored by Git).
#   4. Points Git at .githooks\ so the pre-commit hook runs gitleaks on every commit.
#   5. Runs a self-test: a fake key must be caught, and a clean file must pass.

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = (& git rev-parse --show-toplevel).Trim()
if (-not $repoRoot) { throw 'Run this script inside the repository.' }
Set-Location $repoRoot

# 1. Read pinned values
$pins = @{}
Get-Content (Join-Path $repoRoot 'tools\ci\tool-versions.env') | ForEach-Object {
  if ($_ -match '^\s*([A-Z0-9_]+)=(.+?)\s*$') { $pins[$Matches[1]] = $Matches[2] }
}
$version = $pins['GITLEAKS_VERSION']
$expected = $pins['GITLEAKS_SHA256_WINDOWS_X64'].ToLower()
if (-not $version -or -not $expected) { throw 'Pinned gitleaks values are missing in tools\ci\tool-versions.env.' }

# 2. Download and verify
$url = "https://github.com/gitleaks/gitleaks/releases/download/v$version/gitleaks_${version}_windows_x64.zip"
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("gitleaks-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
$zip = Join-Path $tmp 'gitleaks.zip'
Write-Host "Downloading gitleaks $version ..."
Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $zip
$actual = (Get-FileHash -Algorithm SHA256 -Path $zip).Hash.ToLower()
if ($actual -ne $expected) {
  Remove-Item -Recurse -Force $tmp
  throw "Checksum mismatch. Expected $expected but got $actual. Nothing was installed."
}
Write-Host 'Checksum OK.'

# 3. Install
$binDir = Join-Path $repoRoot 'tools\bin'
New-Item -ItemType Directory -Force -Path $binDir | Out-Null
Expand-Archive -Path $zip -DestinationPath $tmp -Force
Copy-Item -Force (Join-Path $tmp 'gitleaks.exe') (Join-Path $binDir 'gitleaks.exe')
Remove-Item -Recurse -Force $tmp
$gl = Join-Path $binDir 'gitleaks.exe'
& $gl version

# 4. Turn on the hook
& git config core.hooksPath .githooks
Write-Host 'Git now uses .githooks\ for hooks.'

# 5. Self-test (the fake key is assembled at run time so this file itself is clean)
$testDir = Join-Path ([System.IO.Path]::GetTempPath()) ("gl-selftest-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testDir | Out-Null
$fakeKey = 'sk-ant-' + 'api03-' + ('A' * 40) + '_fakefakefakefake'
Set-Content -Path (Join-Path $testDir 'canary.txt') -Value "ANTHROPIC_API_KEY=$fakeKey"
& $gl dir --no-banner --config (Join-Path $repoRoot '.gitleaks.toml') $testDir 2>&1 | Out-Null
$caught = ($LASTEXITCODE -ne 0)
Set-Content -Path (Join-Path $testDir 'canary.txt') -Value 'nothing secret here'
& $gl dir --no-banner --config (Join-Path $repoRoot '.gitleaks.toml') $testDir 2>&1 | Out-Null
$clean = ($LASTEXITCODE -eq 0)
Remove-Item -Recurse -Force $testDir
if ($caught -and $clean) {
  Write-Host 'Self-test passed: a fake key is blocked and a clean file passes.' -ForegroundColor Green
} else {
  throw "Self-test FAILED (fake key caught: $caught, clean file passed: $clean)."
}

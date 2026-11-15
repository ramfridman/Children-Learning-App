# Builds, signs and checks the four bundled packs (starter 0.12.0, lang-eng/heb/rus 1.0.0) with the owner's key.
# Run from anywhere:   & 'D:\nitznutz-teach-first\tools\sign-l7-packs.ps1'
# The key is read by the repo's own tool from %USERPROFILE%\nitznutz-secrets\pack-signing.key. This script never opens,
# copies or prints it; it only checks that the file exists. Safe to run again: every step rebuilds from the sources.
# PowerShell 5.1. Stops at the first error.

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$app = Join-Path $repo 'app'
$packs = Join-Path $app 'assets\packs'
$keyPath = Join-Path $env:USERPROFILE 'nitznutz-secrets\pack-signing.key'

function Step([string]$text) { Write-Host ''; Write-Host "== $text" -ForegroundColor Cyan }
function Check([string]$what) {
    if ($LASTEXITCODE -ne 0) { throw "FAILED: $what (exit code $LASTEXITCODE)" }
}

try {
    if (-not (Test-Path -LiteralPath $keyPath)) {
        throw "The signing key is not at $keyPath. Nothing was changed."
    }

    # The versions come from the sources, so the file names below follow them.
    $starterVersion = (Get-Content -Raw -Encoding UTF8 (Join-Path $repo 'content\starter\pack.json') | ConvertFrom-Json).version
    $langVersions = @{}
    foreach ($c in 'eng', 'heb', 'rus') {
        $langVersions[$c] = (Get-Content -Raw -Encoding UTF8 (Join-Path $repo "content\languages\$c\pack\pack.json") | ConvertFrom-Json).version
    }
    $wanted = @("starter-$starterVersion")
    foreach ($c in 'eng', 'heb', 'rus') { $wanted += "lang-$c-$($langVersions[$c])" }
    Write-Host ('Packs to sign: ' + ($wanted -join ', '))

    Step '1. The sources are up to date (neither command may change a file)'
    Push-Location $repo
    python tools\regen_content.py
    Check 'regen_content.py'
    python tools\lang_pack.py all --check
    Check 'lang_pack.py all --check (run: python tools\lang_pack.py all, and tell Claude)'
    Pop-Location

    Push-Location $app
    try {
        Step '2. Build and sign the starter pack'
        dart run tool/pack_builder.dart build ..\content\starter --out assets\packs
        Check 'build starter'

        Step '3. Build and sign the three language packs (older language packs are removed by the tool)'
        dart run tool/pack_builder.dart build-language all
        Check 'build-language all'

        Step '4. Remove every other pack file from the bundle folder'
        foreach ($f in Get-ChildItem -LiteralPath $packs -Filter '*.nnpack') {
            $name = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
            if ($f.Name -match '^(starter|lang-(eng|heb|rus))-' -and $wanted -notcontains $name) {
                Remove-Item -LiteralPath $f.FullName
                Write-Host "Removed $($f.Name)"
            }
        }

        Step '5. Verify all four against the public key built into the app'
        foreach ($name in $wanted) {
            dart run tool/pack_builder.dart verify "assets\packs\$name.nnpack"
            Check "verify $name"
        }

        Step '6. Regenerate the shared publish vector from the new starter pack'
        $env:NN_UPDATE_VECTORS = '1'
        try { flutter test test/publish_test.dart } finally { Remove-Item Env:\NN_UPDATE_VECTORS -ErrorAction SilentlyContinue }
        Check 'publish_test (vector update)'

        Step '7. The pack tests (the starter test takes several minutes)'
        flutter test test/language_packs_build_test.dart test/starter_pack_test.dart test/bundled_language_packs_test.dart test/publish_test.dart
        Check 'pack tests'
    }
    finally {
        Pop-Location
    }

    Write-Host ''
    Write-Host 'PASS: four packs signed, verified, and the pack tests are green.' -ForegroundColor Green
    Write-Host 'Files for Claude to commit:'
    git -C $repo status --short -- app/assets/packs testvectors
    Write-Host ''
    Write-Host 'Now tell Claude "signed".'
}
catch {
    Write-Host ''
    Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Copy the red line and the last lines above to Claude. No key was printed.'
    exit 1
}

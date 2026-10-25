# M0 proof that the closed `app` schema and storage cannot be reached through Supabase's own APIs,
# even with a valid signed-in session. Run from the repository root:
#
#   powershell -ExecutionPolicy Bypass -File tools\data-api-closed-check.ps1
#
# It reads the project URL and the publishable key from app\config\dev.local.json (the same file the
# app is built with), asks for your email and the six-digit code that Supabase emails you, then
# calls the Data API and Storage as the signed-in user. It prints only a status and PASS or FAIL per
# check. The code is read without echo, and the session token stays inside this process: it is never
# printed, logged or written to disk.

$ErrorActionPreference = 'Stop'
$cfgPath = Join-Path $PSScriptRoot '..\app\config\dev.local.json'
if (-not (Test-Path $cfgPath)) { throw "Missing $cfgPath (see docs/setup/android-device-checks.md, section 1)." }
$cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
$url = $cfg.SUPABASE_URL.TrimEnd('/')
$key = $cfg.SUPABASE_PUBLISHABLE_KEY
if ($key -notlike 'sb_publishable_*') { throw 'SUPABASE_PUBLISHABLE_KEY must be the sb_publishable_ key.' }

function Invoke-Api([string]$Method, [string]$Path, [hashtable]$Headers, [string]$Body) {
  $tmp = $null
  $argv = @('-s', '-m', '30', '-X', $Method, '-o', '-', '-w', "`n%{http_code}", "$url$Path")
  foreach ($k in $Headers.Keys) { $argv += @('-H', "${k}: $($Headers[$k])") }
  if ($Body) {
    $tmp = [IO.Path]::GetTempFileName()
    [IO.File]::WriteAllText($tmp, $Body)
    $argv += @('-H', 'content-type: application/json', '--data-binary', "@$tmp")
  }
  try { $out = (& curl.exe @argv) -join "`n" } finally { if ($tmp) { Remove-Item $tmp -Force } }
  $i = $out.LastIndexOf("`n")
  [pscustomobject]@{ Status = [int]$out.Substring($i + 1); Text = $out.Substring(0, [Math]::Max($i, 0)) }
}

# ---- sign in (the token never leaves this variable) ----
$email = Read-Host 'Email of your Supabase user'
$r = Invoke-Api POST '/auth/v1/otp' @{ apikey = $key } (@{ email = $email; create_user = $false } | ConvertTo-Json -Compress)
if ($r.Status -ne 200) { throw "Could not send the code (http $($r.Status))." }
$secure = Read-Host 'Six-digit code from the email' -AsSecureString
$code = [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
$r = Invoke-Api POST '/auth/v1/verify' @{ apikey = $key } (@{ type = 'email'; email = $email; token = $code } | ConvertTo-Json -Compress)
if ($r.Status -ne 200) { throw "Sign-in failed (http $($r.Status))." }
$token = ($r.Text | ConvertFrom-Json).access_token
if (-not $token) { throw 'No session returned.' }
Write-Host 'Signed in. Running the checks as that user...' -ForegroundColor Cyan

$auth = @{ apikey = $key; Authorization = "Bearer $token" }
$results = @()
function Check([string]$Name, $Resp, [scriptblock]$Pass) {
  $ok = & $Pass $Resp
  $script:results += $ok
  $word = if ($ok) { 'PASS' } else { 'FAIL' }
  $color = if ($ok) { 'Green' } else { 'Red' }
  Write-Host ("{0}  {1}  (http {2})" -f $word, $Name, $Resp.Status) -ForegroundColor $color
}

# 1. Every table of the closed schema, read as the signed-in user: the schema must be refused.
foreach ($t in 'family', 'guardian', 'device', 'enroll_challenge', 'pairing_code', 'request_nonce', 'dev_device_allowlist', 'config') {
  $resp = Invoke-Api GET "/rest/v1/${t}?select=*" ($auth + @{ 'Accept-Profile' = 'app' })
  Check "Data API read app.$t is refused" $resp { param($x) $x.Status -ge 400 -and $x.Text -match 'PGRST106' }
}
# 2. Writes and function calls into the closed schema.
$resp = Invoke-Api POST '/rest/v1/family' ($auth + @{ 'Content-Profile' = 'app' }) '{}'
Check 'Data API insert into app.family is refused' $resp { param($x) $x.Status -ge 400 -and $x.Text -match 'PGRST106' }
$resp = Invoke-Api POST '/rest/v1/rpc/anything' ($auth + @{ 'Content-Profile' = 'app' }) '{}'
Check 'Data API call of a function in app is refused' $resp { param($x) $x.Status -ge 400 -and $x.Text -match 'PGRST106' }
# 3. The same table names in the open schema do not exist either.
$resp = Invoke-Api GET '/rest/v1/device?select=*' $auth
Check 'public.device does not exist' $resp { param($x) $x.Status -eq 404 }
# 4. Storage: nothing to list, read or write.
$resp = Invoke-Api GET '/storage/v1/bucket' $auth
Check 'Storage lists no buckets' $resp { param($x) $x.Status -ge 400 -or $x.Text.Trim() -eq '[]' }
$resp = Invoke-Api POST '/storage/v1/object/list/anything' $auth '{"prefix":"","limit":10}'
Check 'Storage object list of a bucket is refused' $resp { param($x) $x.Status -ge 400 -or $x.Text.Trim() -eq '[]' }
$resp = Invoke-Api POST '/storage/v1/bucket' $auth '{"name":"probe","public":true}'
Check 'Storage bucket creation is refused' $resp { param($x) $x.Status -ge 400 }
$resp = Invoke-Api POST '/storage/v1/object/probe/probe.txt' $auth 'x'
Check 'Storage upload is refused' $resp { param($x) $x.Status -ge 400 }

$token = $null
$failed = ($results | Where-Object { -not $_ }).Count
Write-Host ''
if ($failed -eq 0) { Write-Host "All $($results.Count) checks passed." -ForegroundColor Green } else { Write-Host "$failed of $($results.Count) checks FAILED." -ForegroundColor Red; exit 1 }

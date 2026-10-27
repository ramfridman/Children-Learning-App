# Makes a new publish secret for the content and pre-warm tools, sets it on the Supabase project and saves it as the
# user's own Windows variable NITZNUTZ_PUBLISH_SECRET (this shell gets it at once, new windows get it by themselves).
# The value is never printed and never written anywhere else: it goes to a temporary file for the one CLI call, and the
# file is deleted straight after. The old secret stops working.
$ErrorActionPreference = 'Stop'
$projectRef = 'ungkvkabqxssggttajfs'

$bytes = New-Object byte[] 36
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($bytes)
$value = ($bytes | ForEach-Object { $_.ToString('x2') }) -join ''

$tmp = Join-Path $env:TEMP ([guid]::NewGuid().ToString() + '.env')
try {
  Set-Content -Path $tmp -Value ('CONTENT_PUBLISH_SECRET=' + $value) -Encoding ascii
  npx supabase secrets set --env-file $tmp --project-ref $projectRef | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'supabase secrets set failed; nothing was changed on this computer' }
}
finally {
  if (Test-Path $tmp) { Remove-Item $tmp -Force }
}

[Environment]::SetEnvironmentVariable('NITZNUTZ_PUBLISH_SECRET', $value, 'User')
$env:NITZNUTZ_PUBLISH_SECRET = $value
Write-Host ('new publish secret set on the project and in your user variable (' + $value.Length + ' characters); the value is not shown')

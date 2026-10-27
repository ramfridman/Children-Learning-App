# Gives the read-only database login `backup_reader` a new random password and saves the full connection address for the
# weekly backup in C:\Users\ramfr\nitznutz-secrets\backup-database-url.txt (outside the repository). The password is
# never printed: it goes to a temporary file for the one CLI call, and the file is deleted straight after. Running it
# again makes a new password; the old address stops working.
$ErrorActionPreference = 'Stop'
$projectRef = 'ungkvkabqxssggttajfs'
$poolerHost = 'aws-1-eu-central-1.pooler.supabase.com'
$out = Join-Path $env:USERPROFILE 'nitznutz-secrets\backup-database-url.txt'

$bytes = New-Object byte[] 30
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
# Letters and digits only, so the password needs no escaping in an address.
$password = (($bytes | ForEach-Object { $_.ToString('x2') }) -join '')

$tmp = Join-Path $env:TEMP ([guid]::NewGuid().ToString() + '.sql')
try {
  Set-Content -Path $tmp -Value ("alter role backup_reader password '" + $password + "';") -Encoding ascii
  npx supabase db query --linked -f $tmp | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'setting the password failed; nothing was saved on this computer' }
}
finally {
  if (Test-Path $tmp) { Remove-Item $tmp -Force }
}

New-Item -ItemType Directory -Force (Split-Path $out) | Out-Null
$url = 'postgresql://backup_reader.' + $projectRef + ':' + $password + '@' + $poolerHost + ':5432/postgres?sslmode=require'
Set-Content -Path $out -Value $url -Encoding ascii -NoNewline
Write-Host ('backup login password set; the address is saved in ' + $out + ' (' + $url.Length + ' characters); the value is not shown')

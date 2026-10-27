# Puts content/tutor-moves.json into the Supabase project's config table (key tutor_moves), where the AI helper reads
# its teaching moves. Plain English text only, no secret. Run from the repository root.
$ErrorActionPreference = 'Stop'
$file = Join-Path $PSScriptRoot '..\content\tutor-moves.json'
$doc = Get-Content -Raw -Encoding UTF8 $file | ConvertFrom-Json
$json = $doc.moves | ConvertTo-Json -Depth 10 -Compress
if ($json -match '[^\x20-\x7E]') { throw 'the moves must be plain ASCII English' }
$sqlFile = Join-Path $env:TEMP ([guid]::NewGuid().ToString() + '.sql')
try {
  $escaped = $json.Replace("'", "''")
  Set-Content -Path $sqlFile -Value ("insert into app.config (key, value) values ('tutor_moves', '" + $escaped + "'::jsonb) on conflict (key) do update set value = excluded.value, updated_at = now() returning key;") -Encoding ascii
  npx supabase db query --linked -f $sqlFile
  if ($LASTEXITCODE -ne 0) { throw 'the config row was not written' }
}
finally {
  if (Test-Path $sqlFile) { Remove-Item $sqlFile -Force }
}

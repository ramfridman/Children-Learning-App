# Adds, removes or lists the addresses that may create a Nitznutz account (the sign-up allowlist,
# docs/setup/open-signup.md). It changes the table signup_gate.approved_email on the linked Supabase project through
# `npx supabase db query --linked`, so it is run by the orchestrator, with the owner's OK, from the repository folder
# after `npx supabase login` and the link of docs/setup/supabase-deploy.md step 1:
#
#   powershell -ExecutionPolicy Bypass -File tools\signup-allowlist.ps1 -Add name@example.com, other@example.com
#   powershell -ExecutionPolicy Bypass -File tools\signup-allowlist.ps1 -Remove name@example.com
#   powershell -ExecutionPolicy Bypass -File tools\signup-allowlist.ps1 -List
#   powershell -ExecutionPolicy Bypass -File tools\signup-allowlist.ps1 -Count
#   powershell -ExecutionPolicy Bypass -File tools\signup-allowlist.ps1 -Add name@example.com -DryRun
#
# The addresses live only in the live database. This script reads them from its parameters and writes nothing to
# disk. Never put a list of addresses in the repository, in a commit message or in a pull request. -List prints the
# addresses to this window only; use -Count when you only need to know how many there are.
#
# Every address is trimmed and lower-cased by the database itself (signup_gate.normalise_email), the same way the
# sign-up hook compares them. A plus-alias is a different address. An address of an odd shape is refused here, and
# again by the table.

[CmdletBinding()]
param(
  [string[]]$Add = @(),
  [string[]]$Remove = @(),
  [switch]$List,
  [switch]$Count,
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# The same shape the table accepts (after trimming and lower-casing). No quote, backslash or space can pass, so the
# addresses can be written between single quotes in the statement below.
$shape = '^[a-z0-9._%+-]{1,64}@[a-z0-9-]+(\.[a-z0-9-]+)+$'

# `powershell -File` hands "a@b.com, c@d.org" over as one string, so every value is also split at commas, semicolons
# and white space.
function ConvertTo-Clean([string[]]$Addresses) {
  foreach ($a in ($Addresses -split '[,;\s]+' | Where-Object { $_ -ne '' })) {
    $t = $a.Trim().ToLowerInvariant()
    if ($t.Length -gt 254 -or $t -notmatch $shape) { throw "Not an address this list can hold: a value you gave has a shape that is not allowed." }
    $t
  }
}

function Invoke-Sql([string]$Sql) {
  if ($DryRun) { Write-Host $Sql; return }
  npx supabase db query --linked $Sql
  if ($LASTEXITCODE -ne 0) { throw "supabase db query failed (exit $LASTEXITCODE)." }
}

if ($Add.Count -eq 0 -and $Remove.Count -eq 0 -and -not $List -and -not $Count) {
  throw 'Give -Add, -Remove, -List or -Count.'
}

if ($Add.Count -gt 0) {
  $values = (ConvertTo-Clean $Add | ForEach-Object { "('$_')" }) -join ', '
  Invoke-Sql @"
insert into signup_gate.approved_email (email)
select signup_gate.normalise_email(v.email) from (values $values) as v(email)
on conflict (email) do nothing;
select count(*) as approved_now from signup_gate.approved_email;
"@
}

if ($Remove.Count -gt 0) {
  $values = (ConvertTo-Clean $Remove | ForEach-Object { "('$_')" }) -join ', '
  Invoke-Sql @"
delete from signup_gate.approved_email
 where email in (select signup_gate.normalise_email(v.email) from (values $values) as v(email));
select count(*) as approved_now from signup_gate.approved_email;
"@
}

if ($Count) {
  Invoke-Sql 'select count(*) as approved_now from signup_gate.approved_email;'
}

if ($List) {
  Invoke-Sql 'select email, added_at from signup_gate.approved_email order by added_at, email;'
}

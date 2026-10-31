$ErrorActionPreference = 'Stop'

# The install's own bookkeeping: the choco-bin shim first (it forwards
# into the MSI's tree), then the MSI itself — its per-machine entries
# (the PATH rows, Program Files, the product registration) leave through
# msiexec /x against the product's Uninstall hive entry (resolved by
# display name; the product code is the MSI's own, never hardcoded here).
Uninstall-BinFile -Name 'metanorma' -ErrorAction SilentlyContinue

$entry = Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' `
  -ErrorAction SilentlyContinue |
  Where-Object { $_.DisplayName -like 'Metanorma*' } |
  Select-Object -First 1
if ($entry -and $entry.UninstallString) {
  $guid = $entry.UninstallString -replace '.*({[0-9A-Fa-f-]+}).*', '$1'
  $p = Start-Process msiexec.exe -Wait -PassThru -ArgumentList '/x', $guid, '/qn', '/norestart'
  if ($p.ExitCode -ne 0) { Write-Warning "msiexec /x exited $($p.ExitCode)" }
}

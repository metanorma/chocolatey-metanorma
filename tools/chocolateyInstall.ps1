$ErrorActionPreference = 'Stop'

# Thin wrapper: the signed MSI from the packed-metanorma release does the
# real work (per-machine install under Program Files, system PATH wiring,
# runtime seeded at install time). This script only downloads and verifies
# it. url64bit/checksum64 are refreshed by build.ps1 on every release.

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  installerType  = 'msi'
  url64bit       = 'https://github.com/metanorma/packed-metanorma/releases/download/v1.17.0-1/metanorma-setup-1.17.0-windows-ucrt64.msi'
  checksum64     = '02e86c4b49bfe9b50e16d8adede0c9fda4b015addc5a0f86d72364cfbd5488bb'
  checksumType64 = 'sha256'
  silentArgs     = '/qn /norestart'
  validExitCodes = @(0, 3010, 1641)
}

Install-ChocolateyPackage @packageArgs
Install-ChocolateyPackage @packageArgs

# The MSI wires the MACHINE PATH — but a running process never re-reads
# it, and on CI each later step inherits the job-start snapshot, so the
# exe stays unreachable even though the install succeeded
# (metanorma/packed-metanorma#274: the generate legs red fleet-wide).
# Register the Chocolatey shim in the choco bin dir, which IS on PATH
# from job start. The shim targets the MSI's zero-config dispatch entry
# (home\shims\metanorma.exe — the packed-metanorma rehearsal's proven
# path); the install root resolves from the product's registry
# InstallDir first, the default location as the fallback.
$reg = Get-ItemProperty 'HKLM:\Software\Metanorma\metanorma' -ErrorAction SilentlyContinue
$installRoot = if ($reg -and $reg.InstallDir) { $reg.InstallDir } else { "C:\Program Files\metanorma" }
$exe = Join-Path $installRoot 'home\shims\metanorma.exe'
if (Test-Path $exe) {
  Install-BinFile -Name 'metanorma' -Path $exe
} else {
  Write-Warning "metanorma.exe not found at $exe — the zero-config shim did not land; a NEW shell still resolves it from the system PATH."
}

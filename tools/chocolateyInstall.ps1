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

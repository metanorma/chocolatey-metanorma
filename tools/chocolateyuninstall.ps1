$ErrorActionPreference = 'Stop'

# Uninstall metanorma executable
Write-Host "Uninstalling metanorma..." -ForegroundColor Green

try {
  Uninstall-BinFile -Name "metanorma"
  Write-Host "Metanorma executable unregistered from PATH" -ForegroundColor Yellow
} catch {
  Write-Warning "Could not unregister metanorma executable: $_"
}

# Uninstall xml2rfc if it was registered by this package
try {
  Uninstall-BinFile -Name "xml2rfc"
  Write-Host "xml2rfc executable unregistered from PATH" -ForegroundColor Yellow
} catch {
  # xml2rfc may not have been registered as an executable, which is fine
  Write-Host "xml2rfc was not registered as an executable (this is normal)" -ForegroundColor Yellow
}

# Clean up metanorma.exe from tools directory
$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$exePath = Join-Path $toolsDir "metanorma.exe"

if (Test-Path $exePath) {
  try {
    Remove-Item -Path $exePath -Force
    Write-Host "Metanorma executable removed from tools directory" -ForegroundColor Yellow
  } catch {
    Write-Warning "Could not remove metanorma executable from tools directory: $_"
  }
} else {
  Write-Host "Metanorma executable not found in tools directory (already removed)" -ForegroundColor Yellow
}

# Note about xml2rfc: We don't uninstall xml2rfc via pip because:
# 1. It was installed with --user flag, so it's in user's Python environment
# 2. Other applications might depend on it
# 3. It's a best practice to leave user-installed Python packages intact
Write-Host "Note: xml2rfc Python package remains installed for potential use by other applications" -ForegroundColor Yellow

Write-Host "Metanorma uninstallation completed successfully!" -ForegroundColor Green

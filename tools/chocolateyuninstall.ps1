$ErrorActionPreference = 'Stop'

# Uninstall metanorma executable
Write-Host "Uninstalling metanorma..." -ForegroundColor Green

try {
  Uninstall-BinFile -Name "metanorma"
  Write-Host "Metanorma executable unregistered from PATH" -ForegroundColor Yellow
} catch {
  Write-Warning "Could not unregister metanorma executable: $_"
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

# Note: xml2rfc is handled by the xml2rfc chocolatey package dependency
# and will be uninstalled automatically when metanorma is uninstalled

Write-Host "Metanorma uninstallation completed successfully!" -ForegroundColor Green

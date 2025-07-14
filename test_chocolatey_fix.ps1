# Test script to verify chocolatey installation fix
$ErrorActionPreference = 'Stop'

Write-Host "Testing chocolatey metanorma installation fix..." -ForegroundColor Green

# Clean up any existing installation
Write-Host "Cleaning up existing installation..." -ForegroundColor Yellow
try {
    choco uninstall metanorma -y --force
} catch {
    Write-Host "No existing installation found" -ForegroundColor Gray
}

# Test the installation
Write-Host "Installing metanorma with fixed script..." -ForegroundColor Yellow
try {
    choco install metanorma --source . -y --force

    # Check if metanorma.exe is available
    $shimPath = "$($Env:ChocolateyInstall)\bin\metanorma.exe"
    if (Test-Path $shimPath) {
        Write-Host "SUCCESS: Metanorma shim found at $shimPath" -ForegroundColor Green

        # Test the shim
        try {
            $version = & $shimPath --version 2>&1
            Write-Host "SUCCESS: Metanorma version: $version" -ForegroundColor Green
        } catch {
            Write-Host "WARNING: Metanorma shim exists but version check failed: $_" -ForegroundColor Yellow
        }
    } else {
        Write-Host "ERROR: Metanorma shim not found at $shimPath" -ForegroundColor Red
    }

} catch {
    Write-Host "ERROR: Installation failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host "Test completed!" -ForegroundColor Green

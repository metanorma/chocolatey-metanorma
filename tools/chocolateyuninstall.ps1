# Uninstall metanorma executable
Write-Host "Uninstalling metanorma..."
Uninstall-BinFile -Name "metanorma"

# Uninstall xml2rfc if it was installed
$xml2rfcVenvDir = "${env:ChocolateyInstall}\lib\metanorma\xml2rfc-venv"
if (Test-Path $xml2rfcVenvDir) {
    Write-Host "Removing xml2rfc virtual environment..."
    try {
        # Unregister xml2rfc executable
        Uninstall-BinFile -Name "xml2rfc"

        # Remove the virtual environment directory
        Remove-Item -Path $xml2rfcVenvDir -Recurse -Force
        Write-Host "xml2rfc virtual environment removed successfully"
    } catch {
        Write-Warning "Error removing xml2rfc virtual environment: $_"
    }
}

# Clean up metanorma.exe from tools directory
$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$exePath = Join-Path $toolsDir "metanorma.exe"
if (Test-Path $exePath) {
    try {
        Remove-Item -Path $exePath -Force
        Write-Host "Metanorma executable removed from tools directory"
    } catch {
        Write-Warning "Could not remove metanorma executable: $_"
    }
}

Write-Host "Metanorma uninstallation completed!"

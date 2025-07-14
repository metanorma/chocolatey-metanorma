# Install metanorma executable
Write-Host "Installing metanorma..."

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$exePath  = Join-Path $toolsDir "metanorma.exe"
$pkgTools = "$($Env:ChocolateyInstall)/lib/metanorma/tools"
$exeChecksum = Get-Content "$pkgTools\metanorma.sha256.txt" -Head 1
$exeUrl = Get-Content "$pkgTools\metanorma.url.txt" -Head 1

$packageArgs = @{
  PackageName  = 'metanorma'
  Url          = "$exeUrl"
  FileFullPath = "$exePath"
  Checksum     = "$exeChecksum"
  ChecksumType = 'sha256'
}
Get-ChocolateyWebFile @packageArgs

# Register metanorma executable with Chocolatey
Install-BinFile -Name "metanorma" -Path "$exePath"

# Install xml2rfc for IETF support (required)
if (Get-Command "python" -ErrorAction SilentlyContinue) {
	Write-Host "Installing xml2rfc for IETF support..."
	try {
		# Create isolated virtual environment for xml2rfc
		$venvDir = "${env:ChocolateyInstall}\lib\metanorma\xml2rfc-venv"
		Write-Host "Creating virtual environment at: $venvDir"

		$venvOutput = & python -m venv "$venvDir" 2>&1
		if ($LASTEXITCODE -ne 0) {
			Write-Host "Virtual environment creation output: $venvOutput"
			throw "Failed to create virtual environment for xml2rfc (exit code: $LASTEXITCODE)"
		}
		Write-Host "Virtual environment created successfully"

		# Verify virtual environment was created
		$pipExe = "$venvDir\Scripts\pip.exe"
		if (-not (Test-Path $pipExe)) {
			throw "pip executable not found at $pipExe after virtual environment creation"
		}

		# Install xml2rfc in the virtual environment with verbose output
		Write-Host "Upgrading pip in virtual environment..."
		$pipUpgradeOutput = & "$pipExe" install --upgrade pip --verbose 2>&1
		if ($LASTEXITCODE -ne 0) {
			Write-Host "Pip upgrade output: $pipUpgradeOutput"
			throw "Failed to upgrade pip in xml2rfc virtual environment (exit code: $LASTEXITCODE)"
		}
		Write-Host "Pip upgraded successfully"

		Write-Host "Installing xml2rfc..."
		$xml2rfcInstallOutput = & "$pipExe" install xml2rfc --verbose --no-cache-dir 2>&1
		if ($LASTEXITCODE -ne 0) {
			Write-Host "xml2rfc installation output: $xml2rfcInstallOutput"
			throw "Failed to install xml2rfc via pip (exit code: $LASTEXITCODE)"
		}
		Write-Host "xml2rfc installed successfully"

		# Verify xml2rfc executable exists
		$xml2rfcExe = "$venvDir\Scripts\xml2rfc.exe"
		if (-not (Test-Path $xml2rfcExe)) {
			# List contents of Scripts directory for debugging
			$scriptsDir = "$venvDir\Scripts"
			if (Test-Path $scriptsDir) {
				$scriptsContents = Get-ChildItem $scriptsDir | Select-Object Name
				Write-Host "Contents of Scripts directory: $($scriptsContents | Out-String)"
			}
			throw "xml2rfc executable not found after installation at $xml2rfcExe"
		}

		# Register xml2rfc executable with Chocolatey
		Install-BinFile -Name "xml2rfc" -Path "$xml2rfcExe"
		Write-Host "xml2rfc successfully installed and registered at $xml2rfcExe"
	} catch {
		Write-Error "FATAL: xml2rfc installation failed: $_"
		Write-Error "IETF support requires xml2rfc to be properly installed"
		throw "xml2rfc installation failed: $_"
	}
} else {
	Write-Error "FATAL: Python not found - Python is required for xml2rfc installation"
	Write-Error "Please install Python before installing metanorma package"
	throw "Python not found"
}

Write-Host "Metanorma installation completed successfully!"

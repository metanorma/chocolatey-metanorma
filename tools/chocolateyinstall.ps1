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
		& python -m venv "$venvDir"

		if ($LASTEXITCODE -ne 0) {
			throw "Failed to create virtual environment for xml2rfc"
		}

		# Install xml2rfc in the virtual environment
		& "$venvDir\Scripts\pip" install --upgrade pip
		if ($LASTEXITCODE -ne 0) {
			throw "Failed to upgrade pip in xml2rfc virtual environment"
		}

		& "$venvDir\Scripts\pip" install xml2rfc idnits
		if ($LASTEXITCODE -ne 0) {
			throw "Failed to install xml2rfc via pip"
		}

		$xml2rfcExe = "$venvDir\Scripts\xml2rfc.exe"
		if (-not (Test-Path $xml2rfcExe)) {
			throw "xml2rfc executable not found after installation at $xml2rfcExe"
		}

		# Register xml2rfc executable with Chocolatey
		Install-BinFile -Name "xml2rfc" -Path "$xml2rfcExe"
		Write-Host "xml2rfc successfully installed and registered"
	} catch {
		Write-Error "FATAL: xml2rfc installation failed: $_"
		Write-Error "IETF support requires xml2rfc to be properly installed"
		throw "xml2rfc installation failed"
	}
} else {
	Write-Error "FATAL: Python not found - Python is required for xml2rfc installation"
	Write-Error "Please install Python before installing metanorma package"
	throw "Python not found"
}

Write-Host "Metanorma installation completed successfully!"

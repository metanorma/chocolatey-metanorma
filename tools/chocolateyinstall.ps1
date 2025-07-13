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

# Install xml2rfc for IETF support (optional)
if (Get-Command "python" -ErrorAction SilentlyContinue) {
	Write-Host "Installing xml2rfc for IETF support..."
	try {
		# Create isolated virtual environment for xml2rfc
		$venvDir = "${env:ChocolateyInstall}\lib\metanorma\xml2rfc-venv"
		& python -m venv "$venvDir"

		if ($LASTEXITCODE -eq 0) {
			# Install xml2rfc in the virtual environment
			& "$venvDir\Scripts\pip" install --upgrade pip
			& "$venvDir\Scripts\pip" install xml2rfc idnits

			if ($LASTEXITCODE -eq 0) {
				$xml2rfcExe = "$venvDir\Scripts\xml2rfc.exe"
				if (Test-Path $xml2rfcExe) {
					# Register xml2rfc executable with Chocolatey
					Install-BinFile -Name "xml2rfc" -Path "$xml2rfcExe"
					Write-Host "xml2rfc successfully installed and registered"
				} else {
					Write-Warning "xml2rfc executable not found after installation"
				}
			} else {
				Write-Warning "Failed to install xml2rfc via pip, continuing without IETF support..."
			}
		} else {
			Write-Warning "Failed to create virtual environment for xml2rfc, continuing without IETF support..."
		}
	} catch {
		Write-Warning "Error during xml2rfc installation: $_, continuing without IETF support..."
	}
} else {
	Write-Warning "Python not found, skipping xml2rfc installation (IETF support will not be available)"
}

Write-Host "Metanorma installation completed successfully!"

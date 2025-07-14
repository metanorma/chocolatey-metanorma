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
		# Try to find pip command
		$pipCmd = $null
		if (Get-Command "pip" -ErrorAction SilentlyContinue) {
			$pipCmd = "pip"
		} elseif (Get-Command "pip3" -ErrorAction SilentlyContinue) {
			$pipCmd = "pip3"
		} else {
			# Try python -m pip
			$testPip = & python -m pip --version 2>&1
			if ($LASTEXITCODE -eq 0) {
				$pipCmd = "python -m pip"
			} else {
				throw "No pip command found. Please ensure pip is installed."
			}
		}

		Write-Host "Using pip command: $pipCmd"

		# Install xml2rfc using pip directly
		Write-Host "Installing xml2rfc using $pipCmd..."
		$xml2rfcInstallOutput = & cmd /c "$pipCmd install xml2rfc --user --no-cache-dir" 2>&1
		if ($LASTEXITCODE -ne 0) {
			Write-Host "xml2rfc installation output: $xml2rfcInstallOutput"
			throw "Failed to install xml2rfc via pip (exit code: $LASTEXITCODE)"
		}
		Write-Host "xml2rfc installed successfully"

		# Try to find xml2rfc executable in common locations
		$xml2rfcExe = $null
		$possiblePaths = @(
			"$env:APPDATA\Python\Python*\Scripts\xml2rfc.exe",
			"$env:LOCALAPPDATA\Programs\Python\Python*\Scripts\xml2rfc.exe",
			"C:\Python*\Scripts\xml2rfc.exe"
		)

		foreach ($pathPattern in $possiblePaths) {
			$foundPaths = Get-ChildItem -Path $pathPattern -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
			if ($foundPaths) {
				$xml2rfcExe = $foundPaths[0].FullName
				break
			}
		}

		# If not found in common locations, try to find it via python
		if (-not $xml2rfcExe) {
			try {
				$pythonScriptsOutput = & python -c "import site; print(site.getusersitepackages())" 2>&1
				if ($LASTEXITCODE -eq 0) {
					$userSitePackages = $pythonScriptsOutput.Trim()
					$scriptsDir = Join-Path (Split-Path $userSitePackages -Parent) "Scripts"
					$possibleXml2rfc = Join-Path $scriptsDir "xml2rfc.exe"
					if (Test-Path $possibleXml2rfc) {
						$xml2rfcExe = $possibleXml2rfc
					}
				}
			} catch {
				Write-Host "Could not determine user site packages directory"
			}
		}

		if ($xml2rfcExe -and (Test-Path $xml2rfcExe)) {
			# Register xml2rfc executable with Chocolatey
			Install-BinFile -Name "xml2rfc" -Path "$xml2rfcExe"
			Write-Host "xml2rfc successfully installed and registered at $xml2rfcExe"
		} else {
			Write-Warning "xml2rfc executable not found in expected locations, but installation appeared successful"
			Write-Host "xml2rfc may still be available via 'python -m xml2rfc'"
		}
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

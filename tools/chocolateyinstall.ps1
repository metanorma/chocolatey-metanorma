if (Get-Command "python" -errorAction SilentlyContinue) {
	Write-Host "Installing xml2rfc..."
	try {
		& python -m pip install --upgrade pip
		if ($LASTEXITCODE -ne 0) {
			Write-Warning "Failed to upgrade pip, continuing anyway..."
		}

		& python -m pip install idnits xml2rfc
		if ($LASTEXITCODE -ne 0) {
			Write-Warning "Failed to install xml2rfc via pip, continuing with metanorma installation..."
		} else {
			# Verify xml2rfc installation
			$xml2rfcPath = & python -c "import xml2rfc; print(xml2rfc.__file__)" 2>$null
			if ($xml2rfcPath) {
				Write-Host "xml2rfc successfully installed at: $xml2rfcPath"

				# Try to find xml2rfc executable
				$pythonScriptsDir = & python -c "import sys, os; print(os.path.join(sys.prefix, 'Scripts'))" 2>$null
				$xml2rfcExe = Join-Path $pythonScriptsDir "xml2rfc.exe"
				if (Test-Path $xml2rfcExe) {
					Write-Host "xml2rfc executable found at: $xml2rfcExe"
				} else {
					Write-Warning "xml2rfc executable not found in expected location: $xml2rfcExe"
				}
			} else {
				Write-Warning "xml2rfc module verification failed"
			}
		}
	} catch {
		Write-Warning "Error during xml2rfc installation: $_, continuing with metanorma installation..."
	}
} else {
	Write-Warning "Skip installing xml2rfc because no python was found"
}

Write-Host Installing packed-mn...

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

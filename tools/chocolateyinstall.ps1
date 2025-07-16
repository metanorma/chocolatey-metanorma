$ErrorActionPreference = 'Stop'

# Install metanorma executable
Write-Host "Installing metanorma..." -ForegroundColor Green

$packageName = 'metanorma'
$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$exePath = Join-Path $toolsDir "metanorma.exe"
$pkgTools = "$($Env:ChocolateyInstall)/lib/metanorma/tools"

# Validate required files exist
if (-not (Test-Path "$pkgTools\metanorma.sha256.txt")) {
  throw "Required file metanorma.sha256.txt not found in $pkgTools"
}
if (-not (Test-Path "$pkgTools\metanorma.url.txt")) {
  throw "Required file metanorma.url.txt not found in $pkgTools"
}

$exeChecksum = Get-Content "$pkgTools\metanorma.sha256.txt" -Head 1
$exeUrl = Get-Content "$pkgTools\metanorma.url.txt" -Head 1

Write-Host "Downloading metanorma from: $exeUrl" -ForegroundColor Yellow

$packageArgs = @{
  PackageName   = $packageName
  Url           = $exeUrl
  FileFullPath  = $exePath
  Checksum      = $exeChecksum
  ChecksumType  = 'sha256'
}

Get-ChocolateyWebFile @packageArgs

# Verify the downloaded file exists
if (-not (Test-Path $exePath)) {
  throw "Failed to download metanorma executable to $exePath"
}

# Register metanorma executable with Chocolatey
Install-BinFile -Name "metanorma" -Path "$exePath"

# Verify that the shim was created successfully
$shimPath = "$($Env:ChocolateyInstall)\bin\metanorma.exe"
if (Test-Path $shimPath) {
  Write-Host "Metanorma shim created successfully at: $shimPath" -ForegroundColor Green

  # Test that the shim works
  try {
    $versionOutput = & $shimPath --version 2>&1
    if ($LASTEXITCODE -eq 0) {
      Write-Host "Metanorma shim verification successful: $versionOutput" -ForegroundColor Green
    } else {
      Write-Warning "Metanorma shim created but version check failed (exit code: $LASTEXITCODE)"
      Write-Host "Output: $versionOutput" -ForegroundColor Yellow
    }
  } catch {
    Write-Warning "Metanorma shim created but verification failed: $_"
  }
} else {
  Write-Warning "Metanorma shim was not created at expected location: $shimPath"
  Write-Host "Metanorma executable is still available at: $exePath" -ForegroundColor Yellow
}

# Verify xml2rfc is available (provided by xml2rfc dependency)
Write-Host "Verifying xml2rfc availability for IETF support..." -ForegroundColor Green

$xml2rfcAvailable = $false

# Check if xml2rfc is available as a command
if (Get-Command "xml2rfc" -ErrorAction SilentlyContinue) {
  Write-Host "xml2rfc executable found in PATH" -ForegroundColor Green
  $xml2rfcAvailable = $true
} else {
  # Check if xml2rfc is available via python -m xml2rfc
  try {
    $pythonCmd = Get-Command "python" -ErrorAction SilentlyContinue
    if (-not $pythonCmd) {
      $pythonCmd = Get-Command "python3" -ErrorAction SilentlyContinue
    }

    if ($pythonCmd) {
      $xml2rfcVersion = & python -m xml2rfc --version 2>&1
      if ($LASTEXITCODE -eq 0) {
        Write-Host "xml2rfc available via 'python -m xml2rfc'" -ForegroundColor Green
        $xml2rfcAvailable = $true
      }
    }
  } catch {
    # xml2rfc not available via python module
  }
}

if ($xml2rfcAvailable) {
  Write-Host "IETF document processing is supported" -ForegroundColor Green
} else {
  Write-Warning "xml2rfc not found - IETF document processing may not work"
  Write-Warning "This should be provided by the xml2rfc chocolatey dependency"
  Write-Host "Metanorma will still work for non-IETF document types" -ForegroundColor Yellow
}

Write-Host "Metanorma installation completed successfully!" -ForegroundColor Green

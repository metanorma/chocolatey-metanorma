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
Write-Host "Metanorma executable registered successfully" -ForegroundColor Green

# Install xml2rfc for IETF support (required dependency)
Write-Host "Installing xml2rfc for IETF support..." -ForegroundColor Green

$pythonCmd = Get-Command "python" -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
  $pythonCmd = Get-Command "python3" -ErrorAction SilentlyContinue
}

if (-not $pythonCmd) {
  Write-Error "Python is required for xml2rfc installation but was not found in PATH"
  Write-Error "Please install Python from https://www.python.org/ before installing metanorma"
  throw "Python dependency not satisfied"
}

Write-Host "Found Python at: $($pythonCmd.Source)" -ForegroundColor Yellow

try {
  # Determine the best pip command to use
  $pipCmd = $null
  $pipCommands = @("pip", "pip3", "python -m pip")

  foreach ($cmd in $pipCommands) {
    try {
      $testResult = if ($cmd -eq "python -m pip") {
        & python -m pip --version 2>&1
      } else {
        & $cmd --version 2>&1
      }

      if ($LASTEXITCODE -eq 0) {
        $pipCmd = $cmd
        Write-Host "Using pip command: $pipCmd" -ForegroundColor Yellow
        break
      }
    } catch {
      # Continue to next pip command
    }
  }

  if (-not $pipCmd) {
    throw "No working pip installation found. Please ensure pip is installed with Python."
  }

  # Install xml2rfc using the best available pip command
  Write-Host "Installing xml2rfc package..." -ForegroundColor Yellow

  $installArgs = @("install", "xml2rfc", "--user", "--no-cache-dir", "--quiet")

  # Temporarily allow warnings to not break the installation
  $originalErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'

  try {
    if ($pipCmd -eq "python -m pip") {
      $result = & python -m pip @installArgs 2>&1
    } else {
      $result = & $pipCmd @installArgs 2>&1
    }

    if ($LASTEXITCODE -ne 0) {
      Write-Host "pip install output: $result" -ForegroundColor Red
      throw "Failed to install xml2rfc via pip (exit code: $LASTEXITCODE)"
    }

    # Filter out PATH warnings which are common and non-fatal
    $filteredResult = $result | Where-Object { $_ -notmatch "WARNING.*is not on PATH" }
    if ($filteredResult) {
      Write-Host "pip install output: $filteredResult" -ForegroundColor Yellow
    }

    Write-Host "xml2rfc package installed successfully" -ForegroundColor Green
  }
  finally {
    # Restore original error action preference
    $ErrorActionPreference = $originalErrorActionPreference
  }

  # Attempt to locate and register xml2rfc executable
  $xml2rfcExe = $null
  $searchPaths = @(
    "$env:APPDATA\Python\Python*\Scripts\xml2rfc.exe",
    "$env:LOCALAPPDATA\Programs\Python\Python*\Scripts\xml2rfc.exe",
    "C:\Python*\Scripts\xml2rfc.exe"
  )

  foreach ($pathPattern in $searchPaths) {
    $foundPaths = Get-ChildItem -Path $pathPattern -ErrorAction SilentlyContinue |
                  Sort-Object LastWriteTime -Descending
    if ($foundPaths) {
      $xml2rfcExe = $foundPaths[0].FullName
      Write-Host "Found xml2rfc executable at: $xml2rfcExe" -ForegroundColor Yellow
      break
    }
  }

  # Try Python site-packages approach if not found
  if (-not $xml2rfcExe) {
    try {
      $userSiteOutput = & python -c "import site; print(site.getusersitepackages())" 2>&1
      if ($LASTEXITCODE -eq 0) {
        $userSitePackages = $userSiteOutput.Trim()
        $scriptsDir = Join-Path (Split-Path $userSitePackages -Parent) "Scripts"
        $candidatePath = Join-Path $scriptsDir "xml2rfc.exe"
        if (Test-Path $candidatePath) {
          $xml2rfcExe = $candidatePath
          Write-Host "Found xml2rfc executable via site-packages: $xml2rfcExe" -ForegroundColor Yellow
        }
      }
    } catch {
      Write-Host "Could not determine Python user site-packages directory" -ForegroundColor Yellow
    }
  }

  # Register executable if found, otherwise provide fallback information
  if ($xml2rfcExe -and (Test-Path $xml2rfcExe)) {
    Install-BinFile -Name "xml2rfc" -Path "$xml2rfcExe"
    Write-Host "xml2rfc executable registered with Chocolatey" -ForegroundColor Green
  } else {
    Write-Warning "xml2rfc executable not found in standard locations"
    Write-Host "xml2rfc should still be available via 'python -m xml2rfc'" -ForegroundColor Yellow
    Write-Host "This is sufficient for metanorma IETF document processing" -ForegroundColor Yellow
  }

} catch {
  Write-Error "Failed to install xml2rfc dependency: $_"
  Write-Error "IETF document processing requires xml2rfc to be available"
  throw "xml2rfc installation failed: $_"
}

Write-Host "Metanorma installation completed successfully!"

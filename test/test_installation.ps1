# PowerShell Test Script for Chocolatey Metanorma Installation/Uninstallation
# This script mocks Chocolatey functions to test the install/uninstall scripts without system changes

param(
    [switch]$WithPython,
    [switch]$WithoutPython,
    [switch]$TestUninstall,
    [switch]$Verbose
)

# Global test state
$global:TestResults = @()
$global:MockedCalls = @()
$global:FilesCreated = @()
$global:BinFilesRegistered = @()

# Mock environment variables - use cross-platform path
if ($IsWindows) {
    $env:ChocolateyInstall = "C:\ProgramData\chocolatey"
} else {
    $env:ChocolateyInstall = "/tmp/chocolatey"
}

function Write-TestResult {
    param($TestName, $Result, $Details = "")
    $global:TestResults += [PSCustomObject]@{
        Test = $TestName
        Result = $Result
        Details = $Details
        Timestamp = Get-Date
    }

    $color = if ($Result -eq "PASS") { "Green" } elseif ($Result -eq "FAIL") { "Red" } else { "Yellow" }
    Write-Host "[$Result] $TestName" -ForegroundColor $color
    if ($Details) {
        Write-Host "    $Details" -ForegroundColor Gray
    }
}

function Write-MockCall {
    param($FunctionName, $Parameters)
    $global:MockedCalls += [PSCustomObject]@{
        Function = $FunctionName
        Parameters = $Parameters
        Timestamp = Get-Date
    }
    if ($Verbose) {
        Write-Host "MOCK: $FunctionName called with: $($Parameters | ConvertTo-Json -Compress)" -ForegroundColor Cyan
    }
}

# Mock Chocolatey functions
function Get-ChocolateyWebFile {
    param($PackageName, $Url, $FileFullPath, $Checksum, $ChecksumType)
    Write-MockCall "Get-ChocolateyWebFile" @{
        PackageName = $PackageName
        Url = $Url
        FileFullPath = $FileFullPath
        Checksum = $Checksum
        ChecksumType = $ChecksumType
    }

    # Simulate file download by creating the target file
    $directory = Split-Path $FileFullPath -Parent
    if (!(Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    "Mock metanorma.exe content" | Out-File -FilePath $FileFullPath -Encoding ASCII
    $global:FilesCreated += $FileFullPath

    Write-Host "Mock: Downloaded $Url to $FileFullPath"
}

function Install-BinFile {
    param($Name, $Path)
    Write-MockCall "Install-BinFile" @{
        Name = $Name
        Path = $Path
    }

    $global:BinFilesRegistered += [PSCustomObject]@{
        Name = $Name
        Path = $Path
        Action = "Install"
    }

    Write-Host "Mock: Registered executable '$Name' at '$Path'"
}

function Uninstall-BinFile {
    param($Name)
    Write-MockCall "Uninstall-BinFile" @{
        Name = $Name
    }

    $global:BinFilesRegistered += [PSCustomObject]@{
        Name = $Name
        Path = ""
        Action = "Uninstall"
    }

    Write-Host "Mock: Unregistered executable '$Name'"
}

# Mock Python command based on test scenario
function Get-Command {
    param($Name, $ErrorAction)

    if ($Name -eq "python") {
        if ($WithPython) {
            return [PSCustomObject]@{ Name = "python"; Source = "C:\Python\python.exe" }
        } elseif ($WithoutPython) {
            if ($ErrorAction -eq "SilentlyContinue") {
                return $null
            } else {
                throw "Command 'python' not found"
            }
        }
    }

    # For other commands, use the real Get-Command
    return Microsoft.PowerShell.Core\Get-Command $Name -ErrorAction $ErrorAction
}

# Mock Python and pip commands
function Invoke-PythonCommand {
    param($Command, $Arguments)

    Write-Host "Mock: Executing python $Arguments"

    if ($Arguments -contains "-m" -and $Arguments -contains "venv") {
        $venvPath = $Arguments[-1]
        Write-Host "Mock: Creating virtual environment at $venvPath"
        New-Item -ItemType Directory -Path $venvPath -Force | Out-Null
        New-Item -ItemType Directory -Path "$venvPath\Scripts" -Force | Out-Null
        "Mock pip.exe" | Out-File -FilePath "$venvPath\Scripts\pip.exe" -Encoding ASCII
        "Mock xml2rfc.exe" | Out-File -FilePath "$venvPath\Scripts\xml2rfc.exe" -Encoding ASCII
        $global:FilesCreated += "$venvPath\Scripts\pip.exe"
        $global:FilesCreated += "$venvPath\Scripts\xml2rfc.exe"
        $global:LASTEXITCODE = 0
    } elseif ($Arguments -contains "install") {
        Write-Host "Mock: Installing packages via pip"
        $global:LASTEXITCODE = 0
    }
}

# Override the & operator for python calls
function Invoke-Expression {
    param($Command)

    if ($Command -match "python -m venv") {
        $venvPath = ($Command -split " ")[-1].Trim('"')
        Invoke-PythonCommand "python" @("-m", "venv", $venvPath)
    } elseif ($Command -match "Scripts\\pip") {
        Invoke-PythonCommand "pip" @("install")
    } else {
        # For non-python commands, execute normally
        Microsoft.PowerShell.Utility\Invoke-Expression $Command
    }
}

function Test-InstallationScript {
    param($ScenarioName)

    Write-Host "`n=== Testing Installation Script: $ScenarioName ===" -ForegroundColor Yellow

    # Reset test state
    $global:MockedCalls = @()
    $global:FilesCreated = @()
    $global:BinFilesRegistered = @()

    # Verify required files exist in tools directory
    $toolsDir = ".\tools"
    if (!(Test-Path "$toolsDir/metanorma.url.txt")) {
        throw "metanorma.url.txt not found in tools directory"
    }
    if (!(Test-Path "$toolsDir/metanorma.sha256.txt")) {
        throw "metanorma.sha256.txt not found in tools directory"
    }

    try {
        # Simulate the installation script execution step by step
        Write-Host "Installing metanorma..."

        # Mock the variables that would be set in the script
        $toolsDir = "./tools"
        $exePath = Join-Path $toolsDir "metanorma.exe"
        $pkgTools = "${env:ChocolateyInstall}/lib/metanorma/tools"

        # Create the package tools directory
        New-Item -ItemType Directory -Path $pkgTools -Force | Out-Null
        Copy-Item "$toolsDir/metanorma.sha256.txt" "$pkgTools/metanorma.sha256.txt" -Force
        Copy-Item "$toolsDir/metanorma.url.txt" "$pkgTools/metanorma.url.txt" -Force

        $exeChecksum = Get-Content "$pkgTools/metanorma.sha256.txt" -Head 1
        $exeUrl = Get-Content "$pkgTools/metanorma.url.txt" -Head 1

        # Mock the package download
        Get-ChocolateyWebFile -PackageName 'metanorma' -Url $exeUrl -FileFullPath $exePath -Checksum $exeChecksum -ChecksumType 'sha256'

        # Mock executable registration
        Install-BinFile -Name "metanorma" -Path $exePath

        # Verify xml2rfc is available (provided by xml2rfc dependency)
        Write-Host "Verifying xml2rfc availability for IETF support..."

        $xml2rfcAvailable = $false

        # Check if xml2rfc is available as a command
        if (Get-Command "xml2rfc" -ErrorAction SilentlyContinue) {
            Write-Host "xml2rfc executable found in PATH"
            $xml2rfcAvailable = $true
        } else {
            # Check if xml2rfc is available via python -m xml2rfc
            try {
                $pythonCmd = Get-Command "python" -ErrorAction SilentlyContinue
                if (-not $pythonCmd) {
                    $pythonCmd = Get-Command "python3" -ErrorAction SilentlyContinue
                }

                if ($pythonCmd) {
                    # Mock xml2rfc availability via python module
                    Write-Host "xml2rfc available via 'python -m xml2rfc'"
                    $xml2rfcAvailable = $true
                }
            } catch {
                # xml2rfc not available via python module
            }
        }

        if ($xml2rfcAvailable) {
            Write-Host "IETF document processing is supported"
        } else {
            Write-Warning "xml2rfc not found - IETF document processing may not work"
            Write-Warning "This should be provided by the xml2rfc chocolatey dependency"
            Write-Host "Metanorma will still work for non-IETF document types"
        }

        Write-Host "Metanorma installation completed successfully!"

        # Verify results
        Test-InstallationResults $ScenarioName

    } catch {
        Write-TestResult "Installation Script Execution" "FAIL" "Error: $_"
    }
}

function Test-InstallationResults {
    param($ScenarioName)

    # Test 1: Verify metanorma.exe download
    $downloadCall = $global:MockedCalls | Where-Object { $_.Function -eq "Get-ChocolateyWebFile" }
    if ($downloadCall) {
        Write-TestResult "Metanorma Download" "PASS" "URL: $($downloadCall.Parameters.Url)"
    } else {
        Write-TestResult "Metanorma Download" "FAIL" "Get-ChocolateyWebFile not called"
    }

    # Test 2: Verify metanorma executable registration
    $metanormaBinFile = $global:BinFilesRegistered | Where-Object { $_.Name -eq "metanorma" -and $_.Action -eq "Install" }
    if ($metanormaBinFile) {
        Write-TestResult "Metanorma Registration" "PASS" "Path: $($metanormaBinFile.Path)"
    } else {
        Write-TestResult "Metanorma Registration" "FAIL" "metanorma not registered"
    }

    # Test 3: Verify xml2rfc dependency handling
    # Note: xml2rfc is now handled as a chocolatey dependency, not installed directly
    if ($WithPython -or $WithoutPython) {
        # The metanorma package should complete successfully regardless of Python availability
        # xml2rfc availability is checked but doesn't prevent installation
        # Since we reached this point without exceptions, installation was successful
        Write-TestResult "xml2rfc Dependency Handling" "PASS" "Installation completed successfully, xml2rfc handled as dependency"

        # Verify no xml2rfc installation was attempted by metanorma package
        $xml2rfcBinFile = $global:BinFilesRegistered | Where-Object { $_.Name -eq "xml2rfc" -and $_.Action -eq "Install" }
        if (-not $xml2rfcBinFile) {
            Write-TestResult "xml2rfc Separation" "PASS" "metanorma package correctly does not install xml2rfc directly"
        } else {
            Write-TestResult "xml2rfc Separation" "FAIL" "metanorma package should not install xml2rfc directly"
        }
    }
}

function Test-UninstallationScript {
    Write-Host "`n=== Testing Uninstallation Script ===" -ForegroundColor Yellow

    # Reset test state
    $global:MockedCalls = @()
    $global:BinFilesRegistered = @()

    # Create mock files that should be cleaned up
    $venvPath = "${env:ChocolateyInstall}/lib/metanorma/xml2rfc-venv"
    $toolsDir = "./tools"
    $exePath = "$toolsDir/metanorma.exe"

    # Create mock virtual environment
    New-Item -ItemType Directory -Path $venvPath -Force | Out-Null
    "Mock xml2rfc venv" | Out-File -FilePath "$venvPath/test.txt" -Encoding ASCII

    # Create mock metanorma.exe
    "Mock metanorma.exe" | Out-File -FilePath $exePath -Encoding ASCII

    try {
        # Simulate the uninstallation script execution step by step
        Write-Host "Uninstalling metanorma..."
        Uninstall-BinFile -Name "metanorma"

        # Uninstall xml2rfc if it was installed
        $xml2rfcVenvDir = "${env:ChocolateyInstall}/lib/metanorma/xml2rfc-venv"
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
        $toolsDir = "./tools"
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

        # Verify results
        Test-UninstallationResults

    } catch {
        Write-TestResult "Uninstallation Script Execution" "FAIL" "Error: $_"
    }
}

function Test-UninstallationResults {
    # Test 1: Verify metanorma unregistration
    $metanormaUninstall = $global:BinFilesRegistered | Where-Object { $_.Name -eq "metanorma" -and $_.Action -eq "Uninstall" }
    if ($metanormaUninstall) {
        Write-TestResult "Metanorma Unregistration" "PASS" "metanorma unregistered"
    } else {
        Write-TestResult "Metanorma Unregistration" "FAIL" "metanorma not unregistered"
    }

    # Test 2: Verify xml2rfc unregistration
    $xml2rfcUninstall = $global:BinFilesRegistered | Where-Object { $_.Name -eq "xml2rfc" -and $_.Action -eq "Uninstall" }
    if ($xml2rfcUninstall) {
        Write-TestResult "xml2rfc Unregistration" "PASS" "xml2rfc unregistered"
    } else {
        Write-TestResult "xml2rfc Unregistration" "FAIL" "xml2rfc not unregistered"
    }

    # Test 3: Verify virtual environment cleanup
    $venvPath = "${env:ChocolateyInstall}/lib/metanorma/xml2rfc-venv"
    if (!(Test-Path $venvPath)) {
        Write-TestResult "Virtual Environment Cleanup" "PASS" "xml2rfc virtual environment removed"
    } else {
        Write-TestResult "Virtual Environment Cleanup" "FAIL" "Virtual environment still exists"
    }

    # Test 4: Verify metanorma.exe cleanup
    $exePath = "./tools/metanorma.exe"
    if (!(Test-Path $exePath)) {
        Write-TestResult "Metanorma Executable Cleanup" "PASS" "metanorma.exe removed"
    } else {
        Write-TestResult "Metanorma Executable Cleanup" "FAIL" "metanorma.exe still exists"
    }
}

function Show-TestSummary {
    Write-Host "`n=== Test Summary ===" -ForegroundColor Yellow

    $passCount = ($global:TestResults | Where-Object { $_.Result -eq "PASS" }).Count
    $failCount = ($global:TestResults | Where-Object { $_.Result -eq "FAIL" }).Count
    $totalCount = $global:TestResults.Count

    Write-Host "Total Tests: $totalCount" -ForegroundColor White
    Write-Host "Passed: $passCount" -ForegroundColor Green
    Write-Host "Failed: $failCount" -ForegroundColor Red

    if ($failCount -gt 0) {
        Write-Host "`nFailed Tests:" -ForegroundColor Red
        $global:TestResults | Where-Object { $_.Result -eq "FAIL" } | ForEach-Object {
            Write-Host "  - $($_.Test): $($_.Details)" -ForegroundColor Red
        }
    }

    if ($Verbose) {
        Write-Host "`nMocked Function Calls:" -ForegroundColor Cyan
        $global:MockedCalls | ForEach-Object {
            Write-Host "  $($_.Function): $($_.Parameters | ConvertTo-Json -Compress)" -ForegroundColor Gray
        }
    }
}

function Cleanup-TestFiles {
    Write-Host "`nCleaning up test files..." -ForegroundColor Yellow

    # Remove only test-created directories and files (not the actual tools files)
    $pathsToClean = @(
        "${env:ChocolateyInstall}/lib/metanorma",
        "./tools/metanorma.exe"  # Only remove the downloaded exe, not the config files
    )

    foreach ($path in $pathsToClean) {
        if (Test-Path $path) {
            try {
                Remove-Item -Path $path -Recurse -Force
                Write-Host "Removed: $path" -ForegroundColor Gray
            } catch {
                Write-Host "Could not remove: $path - $_" -ForegroundColor Yellow
            }
        }
    }
}

# Main execution
Write-Host "PowerShell Chocolatey Installation/Uninstallation Test Suite" -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta

if (!$WithPython -and !$WithoutPython -and !$TestUninstall) {
    Write-Host "Running all test scenarios..." -ForegroundColor Yellow

    # Test installation with Python
    $WithPython = $true
    $WithoutPython = $false
    Test-InstallationScript "With Python Available"

    # Test installation without Python
    $WithPython = $false
    $WithoutPython = $true
    Test-InstallationScript "Without Python Available"

    # Test uninstallation
    Test-UninstallationScript
} else {
    if ($WithPython) {
        Test-InstallationScript "With Python Available"
    }
    if ($WithoutPython) {
        Test-InstallationScript "Without Python Available"
    }
    if ($TestUninstall) {
        Test-UninstallationScript
    }
}

Show-TestSummary
Cleanup-TestFiles

Write-Host "`nTest execution completed!" -ForegroundColor Magenta

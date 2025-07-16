# base image must respect execution environment windows-2022 in .github/workflows/main.yml
ARG BASE_IMAGE=mcr.microsoft.com/windows/servercore:ltsc2022
# mcr.microsoft.com/dotnet/framework/runtime:4.8 - Windows Server 2019 with .NET Framework 4.8 needed for Chocolatey
# mcr.microsoft.com/windows/servercore:ltsc2022 - Windows Server 2022
# mcr.microsoft.com/windows/servercore:ltsc2025 - Windows Server 2025

### Install Chocolatey in a separate layer
FROM $BASE_IMAGE as chocolatey

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Install Chocolatey using the official installation script
RUN Set-ExecutionPolicy Bypass -Scope Process -Force; \
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; \
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Refresh environment variables to ensure choco is available
RUN Import-Module $env:ChocolateyInstall\helpers\chocolateyProfile.psm1; \
    refreshenv

### Install xml2rfc and metanorma packages in a separate layer
FROM chocolatey as packages

# Copy both packages to a dedicated directory
COPY *.nupkg C:/packages/

# Debug: List files to verify COPY worked and show choco version
RUN Write-Host '=== Chocolatey Version ==='; \
    & $env:ChocolateyInstall\bin\choco.exe --version; \
    Write-Host '=== Files in C:/packages ==='; \
    Get-ChildItem C:/packages -Force | Format-Table Name, Length, LastWriteTime; \
    Write-Host '=== Current working directory ==='; \
    Get-Location; Get-ChildItem -Force

# Install dependencies first, then xml2rfc from local package
RUN Write-Host 'Installing python3 dependency from Chocolatey...' -ForegroundColor Yellow; \
    & $env:ChocolateyInstall\bin\choco.exe install python3 -y --no-progress; \
    if ($LASTEXITCODE -ne 0) { \
        Write-Error 'Failed to install python3 dependency'; \
        exit 1 \
    }

RUN Write-Host 'Installing xml2rfc from downloaded package...' -ForegroundColor Yellow; \
    & $env:ChocolateyInstall\bin\choco.exe install xml2rfc --source='C:/packages' --ignore-dependencies -y --no-progress; \
    if ($LASTEXITCODE -ne 0) { \
        Write-Error 'Failed to install xml2rfc from downloaded package'; \
        exit 1 \
    }; \
    Write-Host 'xml2rfc installed successfully from local package' -ForegroundColor Green

# Verify xml2rfc executables are available
RUN if (Get-Command 'xml2rfc' -ErrorAction SilentlyContinue) { \
        Write-Host '[OK] xml2rfc executable found'; \
        & xml2rfc --version \
    } else { \
        Write-Error 'xml2rfc not available - IETF support requires xml2rfc'; \
        exit 1 \
    };

RUN Write-Host '=== Verifying xml2rfc installation ==='; \
    choco list xml2rfc --limit-output

# Install metanorma from local package and verify installation
RUN Write-Host 'Installing metanorma from local package...' -ForegroundColor Yellow; \
    & $env:ChocolateyInstall\bin\choco.exe install metanorma --source='C:/packages' --ignore-dependencies -y --no-progress; \
    if ($LASTEXITCODE -ne 0) { \
        Write-Error 'Failed to install metanorma from local package'; \
        exit 1 \
    }; \
    Write-Host 'metanorma installed successfully from local package' -ForegroundColor Green

# Verify metanorma executables are available
RUN if (Get-Command 'metanorma' -ErrorAction SilentlyContinue) { \
        Write-Host '[OK] metanorma executable found'; \
        & metanorma version \
    } else { \
        Write-Error 'metanorma executable not found in PATH'; \
        exit 1 \
    };

RUN Write-Host '=== Verifying metanorma installation ==='; \
    choco list metanorma --limit-output

ENTRYPOINT ["powershell.exe", "-ExecutionPolicy", "Bypass"]

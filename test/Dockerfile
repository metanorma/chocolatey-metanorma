# base image must respect execution environment windows-2022 in .github/workflows/main.yml
ARG BASE_IMAGE=mcr.microsoft.com/windows/servercore:ltsc2022
# mcr.microsoft.com/dotnet/framework/runtime:4.8 - Windows Server 2019 with .NET Framework 4.8 needed for Chocolatey
# mcr.microsoft.com/windows/servercore:ltsc2022 - Windows Server 2022
# mcr.microsoft.com/windows/servercore:ltsc2025 - Windows Server 2025

### Install Chocolatey in a separate layer
FROM $BASE_IMAGE AS chocolatey

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Install Chocolatey using the official installation script
RUN Set-ExecutionPolicy Bypass -Scope Process -Force; \
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; \
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Refresh environment variables to ensure choco is available
RUN Import-Module $env:ChocolateyInstall\helpers\chocolateyProfile.psm1; \
    refreshenv

### Install xml2rfc and metanorma packages in a separate layer
FROM chocolatey AS packages

# Copy both packages to a dedicated directory
COPY *.nupkg C:/packages/

# Debug: List files to verify COPY worked and show choco version
RUN Write-Host '=== Chocolatey Version ==='; \
    & $env:ChocolateyInstall\bin\choco.exe --version; \
    Write-Host '=== Files in C:/packages ==='; \
    Get-ChildItem C:/packages -Force | Format-Table Name, Length, LastWriteTime; \
    Write-Host '=== Current working directory ==='; \
    Get-Location; Get-ChildItem -Force

# Enable global confirmation for Chocolatey commands
RUN choco feature enable -n allowGlobalConfirmation

# Install xml2rfc from local package
RUN choco install xml2rfc --source='C:\packages;chocolatey' -y --no-progress

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
RUN choco install metanorma --source='C:\packages;chocolatey' -y --no-progress

# Verify metanorma executables are available
RUN if (Get-Command 'metanorma' -ErrorAction SilentlyContinue) { \
        Write-Host '[OK] metanorma executable found'; \
        & metanorma version \
    } else { \
        Write-Error 'metanorma executable not found in PATH'; \
        exit 1 \
    };

# Java encoding fix (https://github.com/metanorma/metanorma-docker/issues/202)
ENV _JAVA_OPTIONS="-Dstdout.encoding=UTF-8 -Dstderr.encoding=UTF-8"

RUN Write-Host '=== Verifying metanorma installation ==='; \
    choco list metanorma --limit-output

ENTRYPOINT ["powershell.exe", "-ExecutionPolicy", "Bypass"]

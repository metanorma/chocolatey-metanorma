# base image must respect execution environment windows-2022 in .github/workflows/main.yml
FROM mcr.microsoft.com/windows/server:ltsc2022
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Install Chocolatey using the official installation script
RUN Set-ExecutionPolicy Bypass -Scope Process -Force; \
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; \
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Refresh environment variables to ensure choco is available
RUN Import-Module $env:ChocolateyInstall\helpers\chocolateyProfile.psm1; \
    refreshenv

# Copy the local package to a dedicated directory
COPY metanorma.*.nupkg C:/packages/

# Debug: List files to verify COPY worked and show choco version
RUN Write-Host '=== Chocolatey Version ==='; \
    & $env:ChocolateyInstall\bin\choco.exe --version; \
    Write-Host '=== Files in C:/packages ==='; \
    Get-ChildItem C:/packages -Force | Format-Table Name, Length, LastWriteTime; \
    Write-Host '=== Current working directory ==='; \
    Get-Location; Get-ChildItem -Force

# Install from local package using full path to choco
RUN $pkg = Get-ChildItem C:/packages/metanorma.*.nupkg | Select-Object -First 1; \
    if ($pkg) { \
        Write-Host "Installing package: $($pkg.Name)"; \
        & $env:ChocolateyInstall\bin\choco.exe install $pkg.FullName --yes --force --allow-unofficial --no-progress \
    } else { \
        Write-Host 'ERROR: No .nupkg package found in C:/packages'; \
        Get-ChildItem C:/packages -Force; \
        exit 1 \
    }

# Verify installation
RUN Write-Host '=== Verifying metanorma installation ==='; \
    & $env:ChocolateyInstall\bin\choco.exe list --local-only metanorma

ENTRYPOINT ["powershell.exe", "-ExecutionPolicy", "Bypass"]

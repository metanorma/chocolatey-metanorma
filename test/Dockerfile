# base image must respect execution environment windows-2022 in .github/workflows/main.yml
FROM chocolatey/choco:latest-windows

# Copy the local package to a dedicated directory
COPY metanorma.*.nupkg C:/packages/

# Debug: List files to verify COPY worked
RUN powershell -command "Write-Host '=== Files in C:/packages ==='; Get-ChildItem C:/packages -Force | Format-Table Name, Length, LastWriteTime; Write-Host '=== Current working directory ==='; Get-Location; Get-ChildItem -Force"

# Install from local package
RUN powershell -command "$pkg = Get-ChildItem C:/packages/metanorma.*.nupkg | Select-Object -First 1; if ($pkg) { Write-Host \"Installing package: $($pkg.Name)\"; choco install $pkg.FullName --yes --force --allow-unofficial } else { Write-Host 'ERROR: No .nupkg package found in C:/packages'; Get-ChildItem C:/packages -Force; exit 1 }"

# Verify installation
RUN powershell -command "Write-Host '=== Verifying metanorma installation ==='; choco list --local-only metanorma"

ENTRYPOINT ["powershell.exe", "-ExecutionPolicy", "Bypass"]

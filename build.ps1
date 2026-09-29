#Requires -Version 5.1
<#
.SYNOPSIS
  Build (or bump to) the metanorma Chocolatey package for a given product version.

.DESCRIPTION
  Given a Metanorma product version (e.g. 1.17.0), finds the newest
  metanorma/packed-metanorma release that carries
  metanorma-setup-<version>-windows-ucrt64.msi (the tag is NOT assumed to be
  v<version> — v1.17.0-1 ships the 1.17.0 MSI, for example), downloads the
  MSI, computes its SHA256, renders metanorma.nuspec (version + releaseNotes)
  and tools/chocolateyInstall.ps1 (url64bit + checksum64), then packs the
  .nupkg with choco.

  Requires: gh (authenticated or anonymous access to the public release),
  choco.

.EXAMPLE
  ./build.ps1 -Version 1.17.0
#>
param(
  [Parameter(Mandatory = $true)]
  [string]$Version,

  [string]$Repo = 'metanorma/packed-metanorma'
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
$assetName = "metanorma-setup-$Version-windows-ucrt64.msi"

# --- Find the newest release carrying the MSI asset -----------------------
Write-Host "Looking for the newest $Repo release carrying $assetName ..."
$tags = gh release list --repo $Repo --limit 50 --json tagName,isDraft |
  ConvertFrom-Json | Where-Object { -not $_.isDraft } | ForEach-Object { $_.tagName }

$tag = $null
foreach ($candidate in $tags) {
  $assets = gh release view $candidate --repo $Repo --json assets --jq '.assets[].name'
  if ($assets -contains $assetName) {
    $tag = $candidate
    break
  }
}
if (-not $tag) {
  throw "No $Repo release among the newest 50 carries $assetName"
}
Write-Host "Found $assetName on release $tag"

# --- Download the MSI and compute its checksum ----------------------------
$msiPath = Join-Path $env:TEMP $assetName
Remove-Item $msiPath -Force -ErrorAction SilentlyContinue
gh release download $tag --repo $Repo --pattern $assetName --output $msiPath --clobber
$checksum = (Get-FileHash $msiPath -Algorithm SHA256).Hash.ToLower()
Remove-Item $msiPath -Force
Write-Host "SHA256: $checksum"

$msiUrl = "https://github.com/$Repo/releases/download/$tag/$assetName"
$releaseUrl = "https://github.com/$Repo/releases/tag/$tag"

# UTF-8 without BOM, no trailing newline added.
function Write-Utf8File([string]$Path, [string]$Content) {
  [System.IO.File]::WriteAllText($Path, $Content, (New-Object System.Text.UTF8Encoding($false)))
}

# --- Render metanorma.nuspec ----------------------------------------------
$nuspecPath = Join-Path $root 'metanorma.nuspec'
$nuspec = Get-Content $nuspecPath -Raw
$nuspec = $nuspec -replace '(?<=<version>)[^<]+(?=</version>)', $Version
$nuspec = $nuspec -replace '(?<=<releaseNotes>)[^<]+(?=</releaseNotes>)', $releaseUrl
Write-Utf8File $nuspecPath $nuspec

# --- Render tools/chocolateyInstall.ps1 -----------------------------------
$installPath = Join-Path $root 'tools\chocolateyInstall.ps1'
$install = Get-Content $installPath -Raw
$install = $install -replace "(?m)(url64bit\s+=\s+')[^']+(')", ('$1' + $msiUrl + '$2')
$install = $install -replace "(?m)(checksum64\s+=\s+')[^']+(')", ('$1' + $checksum + '$2')
Write-Utf8File $installPath $install

# --- Pack ------------------------------------------------------------------
Push-Location $root
try {
  choco pack
} finally {
  Pop-Location
}

$nupkg = Join-Path $root "metanorma.$Version.nupkg"
if (-not (Test-Path $nupkg)) {
  throw "choco pack did not produce $nupkg"
}
Write-Host "Built $nupkg"

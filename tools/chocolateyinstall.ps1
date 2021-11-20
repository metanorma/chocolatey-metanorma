if (Get-Command "python" -errorAction SilentlyContinue) {
	Write-Host Installing idnits and xml2rfc...
	& python -m pip install --upgrade pip
	& python -m pip install idnits xml2rfc
} else {
	Write-Warning Skip installing idnits and xml2rfc because no python was found
}

Write-Host Installing packed-mn...

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$exePath = Join-Path $toolsDir "metanorma.exe"

$packageArgs = @{
  PackageName  = "metanorma"
  Url          = "https://github.com/metanorma/packed-mn/releases/download/v${Env:ChocolateyPackageVersion}/metanorma-windows-x64.exe"
  FileFullPath = "$exePath"
  Checksum     = '065ffca5429390e4203b216910048b2041659763c82c81b5823e892538913bf0'
  ChecksumType = 'sha256'
}
Get-ChocolateyWebFile @packageArgs

Install-BinFile 'metanorma' "$exePath"

Write-Host Checking metanorma
Get-Command metanorma | Select-Object -ExpandProperty Definition

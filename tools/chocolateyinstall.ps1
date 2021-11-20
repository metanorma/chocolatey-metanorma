if (Get-Command "python" -errorAction SilentlyContinue) {
	Write-Host Installing idnits and xml2rfc...
	& python -m pip install --upgrade pip
	& python -m pip install idnits xml2rfc
} else {
	Write-Warning Skip installing idnits and xml2rfc because no python was found
}

Write-Host Installing packed-mn...

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$exePath  = Join-Path $toolsDir "metanorma.exe"
$checksum = Get-Content "$toolsPath\metanorma.sha256" -Head 1

$packageArgs = @{
  PackageName  = 'metanorma'
  Url          = "https://github.com/metanorma/packed-mn/releases/download/v${Env:ChocolateyPackageVersion}/metanorma-windows-x64.exe"
  FileFullPath = "$exePath"
  Checksum     = "$checksum"
  ChecksumType = 'sha256'
}
Get-ChocolateyWebFile @packageArgs

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
$exeChecksum = Get-Content "$toolsPath\metanorma.sha256.txt" -Head 1
$exeUrl = Get-Content "$toolsPath\metanorma.url.txt" -Head 1

$packageArgs = @{
  PackageName  = 'metanorma'
  Url          = "$exeUrl"
  FileFullPath = "$exePath"
  Checksum     = "$exeChecksum"
  ChecksumType = 'sha256'
}
Get-ChocolateyWebFile @packageArgs

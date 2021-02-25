if (Get-Command "python" -errorAction SilentlyContinue) {
	Write-Host Installing idnits and xml2rfc...
	& python -m pip install --upgrade pip
	& python -m pip install idnits xml2rfc
} else {
	Write-Host Skip installing idnits and xml2rfc because no python was found
}

Write-Host Installing https://tools.ietf.org/tools/idnits/idnits-*.tar archive...

$separator = [IO.Path]::DirectorySeparatorChar
$packageSandboxPath = -join($env:ChocolateyInstall, $separator, "lib", $separator, "metanorma")

$idnitsBaseUrl = "https://tools.ietf.org/tools/idnits/"
$idnitsResponse = Invoke-WebRequest -Uri $idnitsBaseUrl -UseBasicParsing
$idnitsArchive = $idnitsResponse.Links | Where-Object {$_.href -like "idnits-*"} | % { $_.href }

$idnitsDownloadUrl = -join($idnitsBaseUrl, $idnitsArchive)
$idnitsArchivePath = -join($packageSandboxPath, $separator, $idnitsArchive)
Invoke-WebRequest -Uri $idnitsDownloadUrl -OutFile $idnitsArchivePath

Write-Host Show downloaded file 
Get-ChildItem -Path $packageSandboxPath

Get-ChocolateyUnzip -FileFullPath $idnitsArchivePath -Destination $packageSandboxPath

$idnitsPath = -join($packageSandboxPath, $separator, [System.IO.Path]::GetFileNameWithoutExtension($idnitsArchive))
Install-ChocolateyPath -PathToInstall $idnitsArchive

Write-Host Installing packed-mn...

$metanormaUrl = "https://github.com/metanorma/packed-mn/releases/download/v${Env:ChocolateyPackageVersion}/metanorma-windows-x64.exe"
$metanormaPath = -join($Env:ChocolateyInstall, $separator, "bin", $separator, "metanorma.exe")
Invoke-WebRequest -Uri $metanormaUrl -OutFile $metanormaPath

Write-Host Checking metanorma
Get-Command metanorma | Select-Object -ExpandProperty Definition

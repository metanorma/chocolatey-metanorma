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
$idnitsWebPage = -join($packageSandboxPath, $separator, "idnits.html")
Get-WebFile -Url $idnitsBaseUrl -FileName $idnitsWebPage
$idnitsArchive = (Get-Content $idnitsWebPage | Select-String -Pattern 'idnits-.*.tgz' -All).Matches[0].Value

$idnitsDownloadUrl = -join($idnitsBaseUrl, $idnitsArchive)
$idnitsArchivePath = -join($packageSandboxPath, $separator, $idnitsArchive)
Get-ChocolateyWebFile -PackageName ${Env:ChocolateyPackageName} -Url $idnitsDownloadUrl -FileFullPath $idnitsArchivePath

Write-Host Show downloaded file
Get-ChildItem -Path $packageSandboxPath

Get-ChocolateyUnzip -FileFullPath $idnitsArchivePath -Destination $packageSandboxPath

$idnitsPath = -join($packageSandboxPath, $separator, [System.IO.Path]::GetFileNameWithoutExtension($idnitsArchive))
Install-ChocolateyPath -PathToInstall $idnitsArchive

Write-Host Installing packed-mn...

$metanormaUrl = "https://github.com/metanorma/packed-mn/releases/download/v${Env:ChocolateyPackageVersion}/metanorma-windows-x64.exe"
$metanormaPath = -join($Env:ChocolateyInstall, $separator, "bin", $separator, "metanorma.exe")
Get-ChocolateyWebFile -PackageName ${Env:ChocolateyPackageName} -Url $metanormaUrl -FileFullPath $metanormaPath

Write-Host Checking metanorma
Get-Command metanorma | Select-Object -ExpandProperty Definition

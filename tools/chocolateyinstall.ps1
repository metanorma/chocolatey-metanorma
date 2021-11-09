if (Get-Command "python" -errorAction SilentlyContinue) {
	Write-Host Installing idnits and xml2rfc...
	& python -m pip install --upgrade pip
	& python -m pip install idnits xml2rfc
} else {
	Write-Warning Skip installing idnits and xml2rfc because no python was found
}

Write-Host Installing packed-mn...

$metanormaUrl = "https://github.com/metanorma/packed-mn/releases/download/v${Env:ChocolateyPackageVersion}/metanorma-windows-x64.exe"
$metanormaPath = -join($Env:ChocolateyInstall, $separator, "bin", $separator, "metanorma.exe")
Get-ChocolateyWebFile -PackageName ${Env:ChocolateyPackageName} -Url $metanormaUrl -FileFullPath $metanormaPath

Write-Host Checking metanorma
Get-Command metanorma | Select-Object -ExpandProperty Definition

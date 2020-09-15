Write-Host Uninstalling gems...

$metanormaPath = -join($Env:ChocolateyInstall, $separator, "bin", $separator, "metanorma.exe")
Remove-Item -Path $metanormaPath -Force
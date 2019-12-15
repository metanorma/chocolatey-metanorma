Write-Host Installing puppeteer...

& npm i -g puppeteer

if (Get-Command "python" -errorAction SilentlyContinue) {
	Write-Host Installing idnits and xml2rfc...
	& python -m pip install --upgrade pip
	& python -m pip install idnits xml2rfc
} else {
	Write-Host Skip installing idnits and xml2rfc because no python was found
}

Write-Host Installing RIDK...

$RubyGem = "$Env:ChocolateyToolsLocation\ruby25\bin"
$RidkProcess = Start-Process -PassThru -FilePath "$RubyGem\ridk.cmd" -ArgumentList "install 2 3"
# Start-Process prevent Appveyour from hang
Wait-Process -Id $RidkProcess.Id
Update-SessionEnvironment

Write-Host Installing gems...

& $RubyGem\gem.cmd install bundler
& $RubyGem\gem.cmd install metanorma-cli -v $Env:ChocolateyPackageVersion

Write-Host Checking metanorma-cli
Get-Command metanorma | Select-Object -ExpandProperty Definition

# Add LibreOffice CLI to Path
$env:Path = "$Env:ProgramFiles\LibreOffice\program;$Env:Path"

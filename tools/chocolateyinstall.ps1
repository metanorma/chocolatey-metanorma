Write-Host Installing puppeteer...

& npm i -g puppeteer

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

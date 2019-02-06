Set-Content $Env:ChocolateyInstall\bin\xml2-config.bat "@ECHO OFF" -Encoding ASCII
Set-Content $Env:ChocolateyInstall\bin\xslt-config.bat "@ECHO OFF" -Encoding ASCII

$XsltDist = ${Env:ChocolateyInstall} + "\lib\xsltproc\dist"
$XsltInclude = $XsltDist + "\include"
$XsltLib = $XsltDist + "\lib"

Write-Host Installing puppeteer...

& npm i -g puppeteer

Write-Host Installing RIDK...

$RubyGem = "$Env:ChocolateyToolsLocation\ruby25\bin"
$RidkProcess = Start-Process -PassThru -FilePath "$RubyGem\ridk.cmd" -ArgumentList "install 2 3"
# Start-Process prevent Appveyour from hang
Wait-Process -Id $RidkProcess.Id
Update-SessionEnvironment

Write-Host Installing gems...

# Copy with removing version from filename (need because xslt_lib.so expect such names)
Copy-Item -Force $XsltDist\bin\libxml2-*.dll $XsltDist\bin\libxml2.dll
Copy-Item -Force $XsltDist\bin\libxslt-*.dll $XsltDist\bin\libxslt.dll
Copy-Item -Force $XsltDist\bin\libexslt-*.dll $XsltDist\bin\libexslt.dll

& $RubyGem\gem.cmd -v
& $RubyGem\gem.cmd install bundler
& $RubyGem\gem.cmd install metanorma-cli -v $Env:ChocolateyPackageVersion -- `
  --with-xml2-include=$XsltInclude\libxml2 `
  --with-xslt-include=$XsltInclude `
  --with-xml2-lib=$XsltLib `
  --with-xslt-lib=$XsltLib

[Environment]::SetEnvironmentVariable("RUBY_DLL_PATH", "${Env:ChocolateyInstall}\lib\xsltproc\dist\bin;${Env:RUBY_DLL_PATH}", [System.EnvironmentVariableTarget]::Machine)
Update-SessionEnvironment

Write-Host Checking metanorma-cli
Get-Command metanorma | Select-Object -ExpandProperty Definition
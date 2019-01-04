Set-Content $Env:ChocolateyInstall\bin\xml2-config.bat "@ECHO OFF" -Encoding ASCII
Set-Content $Env:ChocolateyInstall\bin\xslt-config.bat "@ECHO OFF" -Encoding ASCII

$XsltDist = ${Env:ChocolateyInstall} + "\lib\xsltproc\dist"
$XsltInclude = $XsltDist + "\include"
$XsltLib = $XsltDist + "\lib"

Write-Host Installing gems...

# Copy with removing version from filename (need because xslt_lib.so expect such names)
Copy-Item -Force $XsltDist\bin\libxml2-*.dll $XsltDist\bin\libxml2.dll 
Copy-Item -Force $XsltDist\bin\libxslt-*.dll $XsltDist\bin\libxslt.dll
Copy-Item -Force $XsltDist\bin\libexslt-*.dll $XsltDist\bin\libexslt.dll

& npm i -g puppeteer

Get-ToolsLocation
$RubyGem = "$Env:ChocolateyToolsLocation\ruby25\bin"

& $RubyGem\gem.cmd -v
& $RubyGem\gem.cmd install bundler
& $RubyGem\gem.cmd install metanorma-cli -v $Env:ChocolateyPackageVersion -- `
  --with-xml2-include=$XsltInclude\libxml2 `
  --with-xslt-include=$XsltInclude `
  --with-xml2-lib=$XsltLib `
  --with-xslt-lib=$XsltLib

& SETX /M RUBY_DLL_PATH "${Env:ChocolateyInstall}\lib\xsltproc\dist\bin;${Env:RUBY_DLL_PATH}"
refreshenv

Write-Host Checking metanorma-cli
Get-Command metanorma | Select-Object -ExpandProperty Definition

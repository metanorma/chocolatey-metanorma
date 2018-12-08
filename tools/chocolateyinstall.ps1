New-Item -ItemType file -Force $Env:ChocolateyInstall\bin\xml2-config.bat
New-Item -ItemType file -Force $Env:ChocolateyInstall\bin\xslt-config.bat

$XsltDist = ${Env:ChocolateyInstall} + "\lib\xsltproc\dist"
$XsltInclude = $XsltDist + "\include"
$XsltLib = $XsltDist + "\lib"
$RubyBin = "c:\tools\ruby25\bin"

Write-Host Installing gems...

Push-Location $RubyBin
gem install bundler 
gem install metanorma-cli -v ${Env:ChocolateyPackageVersion} -- `
  --with-xml2-include=$XsltInclude\libxml2 `
  --with-xslt-include=$XsltInclude `
  --with-xml2-lib=$XsltLib `
  --with-xslt-lib=$XsltLib
Pop-Location

& SETX /M RUBY_DLL_PATH "${Env:ChocolateyInstall}\lib\xsltproc\dist\bin;${env:RUBY_DLL_PATH}"
refreshenv

# Copy with removing version from filename (need because xslt_lib.so expect such names)
Copy-Item -Force $XsltDist\bin\libxml2-*.dll $XsltDist\bin\libxml2.dll 
Copy-Item -Force $XsltDist\bin\libxslt-*.dll $XsltDist\bin\libxslt.dll
Copy-Item -Force $XsltDist\bin\libexslt-*.dll $XsltDist\bin\libexslt.dll

Write-Host List applications...
Get-Command ruby
Get-Command gem
Get-Command bundle
Get-Command java
Get-Command metanorma

metanorma --help
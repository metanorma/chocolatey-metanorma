Write-Host Uninstalling gems...

$RubyGem = "$Env:ChocolateyToolsLocation\ruby25\bin"
& $RubyGem\gem.cmd uninstall --all -x metanorma-cli

$RUBY_DLL_PATH = $Env:RUBY_DLL_PATH.Replace("${Env:ChocolateyInstall}\lib\xsltproc\dist\bin;", "")
[Environment]::SetEnvironmentVariable("RUBY_DLL_PATH", $RUBY_DLL_PATH, [System.EnvironmentVariableTarget]::Machine)
Update-SessionEnvironment
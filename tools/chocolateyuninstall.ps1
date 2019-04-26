Write-Host Uninstalling gems...

$RubyGem = "$Env:ChocolateyToolsLocation\ruby25\bin"
& $RubyGem\gem.cmd uninstall --all -x metanorma-cli
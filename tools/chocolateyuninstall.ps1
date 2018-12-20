Get-ToolsLocation
$RubyGem = "$Env:ChocolateyToolsLocation\ruby25\bin"

Write-Host Uninstalling gems...

& $RubyGem\gem.cmd uninstall --all -x metanorma-cli

$RubyBin = "c:\tools\ruby25\bin"

Write-Host Uninstalling gems...

Push-Location $RubyBin
gem uninstall metanorma-cli
Pop-Location
foreach ($p in $Args) {
	$git_creds = Get-Content C:/ProgramData/docker/secrets/GIT_CREDS -ErrorAction Ignore
	& git clone --recurse-submodules https://${git_creds}@github.com/metanorma/mn-samples-$p.git
	Push-Location mn-samples-$p
	Remove-Item Gemfile
	& metanorma site generate . -c metanorma.yml --agree-to-terms
	if ($? -eq $false) {
  		Write-Host -Background DarkBlue -Foreground Red "metanorma failed"
  		Exit 1
	}
	Pop-Location
}
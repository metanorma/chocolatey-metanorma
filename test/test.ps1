$Args[0].Split() | foreach {
	$git_creds = Get-Content C:/ProgramData/docker/secrets/GIT_CREDS -ErrorAction Ignore
	& git clone --recurse-submodules https://${git_creds}@github.com/metanorma/mn-samples-$_.git
	Push-Location mn-samples-$_
	Remove-Item Gemfile
	& metanorma site generate . -c metanorma.yml --agree-to-terms
	if ($? -eq $false) {
  		Write-Host -Background DarkBlue -Foreground Red "metanorma failed"
  		Exit 1
	}
	Pop-Location
}
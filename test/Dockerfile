# base image must respect execution environment widnows-2019
FROM mcr.microsoft.com/windows:1809
SHELL ["powershell"]

# https://chocolatey.org/install
RUN Set-ExecutionPolicy Bypass -Scope Process -Force; \
	[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; \
	iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# metanorma install
ADD metanorma.*.nupkg .
RUN choco install --no-progress metanorma -dv -y -s "'.;https://chocolatey.org/api/v2/'"

# metanorma test
RUN @('iso'; 'cc'; 'gb'; 'iec'; 'itu'; 'ogc'; 'un') | foreach { \
	$git_creds = Get-Content C:/ProgramData/Docker/secrets/git_creds -ErrorAction Ignore \
	& git clone https://${git_creds}@github.com/metanorma/mn-samples-$_.git \
	Push-Location mn-samples-$_ \
	Remove-Item Gemfile \
	& metanorma site generate . -c metanorma.yml --agree-to-terms \
	Pop-Location \
}
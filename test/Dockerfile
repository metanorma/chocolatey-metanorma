# base image must respect execution environment widnows-2022 in .github/workflows/main.yml
FROM mcr.microsoft.com/windows/server:ltsc2022
SHELL ["powershell"]

# https://chocolatey.org/install
RUN Set-ExecutionPolicy Bypass -Scope Process -Force; \
	[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; \
	iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# metanorma install
ADD metanorma.*.nupkg .
RUN choco install --no-progress metanorma -dv -y -s "'.;https://chocolatey.org/api/v2/'"

ENTRYPOINT ["powershell.exe", "-ExecutionPolicy", "Bypass"]
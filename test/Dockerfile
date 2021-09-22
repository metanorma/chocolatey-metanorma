# base image must respect execution environment widnows-2019 in .github/workflows/main.yml
FROM mcr.microsoft.com/windows:1809
SHELL ["powershell"]

# https://chocolatey.org/install
RUN Set-ExecutionPolicy Bypass -Scope Process -Force; \
	[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; \
	iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# metanorma install
ADD metanorma.*.nupkg .
ADD test.ps1 .
RUN choco install --no-progress metanorma -dv -y -s "'.;https://chocolatey.org/api/v2/'"

ENTRYPOINT ["powershell.exe", "-ExecutionPolicy", "Bypass", "-File", "test.ps1"]
CMD ["iso", "cc", "iec", "itu", "ogc", "un"]
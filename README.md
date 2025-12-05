# Flexapp Automation Command Line Tool
```sh
#Example Usage
./flexapp.exe -i https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi
./flexapp.exe -i https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi -p 132.1.245.1111
./flexapp.exe -i https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi -p 132.1.245.1111 -o //smdhw6huaans01n/flexapp$
./flexapp.exe -i https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi -p 132.1.245.1111 -o //smdhw6huaans01n/flexapp$ -n Chrome
./flexapp.exe -i https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi -p 132.1.245.1111 -o //smdhw6huaans01n/flexapp$ -n Chrome -e "/quiet"
```

## Build
- Minimal Windows Build
```sh
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install mise docker-desktop -y
mise dagger_windows
```

- Minimal Linux Build
```sh
curl https://mise.run | sh
mise dagger_windows
```
# Apps
- Powershell
  - https://github.com/PowerShell/PowerShell/releases/download/v7.5.3/PowerShell-7.5.3-win-x64.msi
- Git
  - https://github.com/git-for-windows/git/releases/download/v2.51.0.windows.1/Git-2.51.0-64-bit.exe
- Chrome
  - https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi
- VSCode
  - https://code.visualstudio.com/sha/download?build=stable&os=win32-x64
- PuTTY
  - https://the.earth.li/~sgtatham/putty/latest/w64/putty-64bit-0.83-installer.msi

# Command
```pwsh
& 'c:\program files (x86)\Liquidware Labs\FlexApp Packaging Automation\fpa-packager.exe' package /Name "avd-rdp-1.25.5623" /PackageVersion 1.25.5623.0 /Path "c:\temp\output" /Installer "C:\temp\new_apps\RemoteDesktop_1.2.5623.0_x64.msi"  /NoSystemRestore
```
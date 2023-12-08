# install_dotnet.ps1
$dotnetInstallerUrl = "https://dotnet.microsoft.com/en-us/download/dotnet/thank-you/sdk-7.0.400-windows-x64-installer"
$dotnetInstallerPath = "C:\dotnet-sdk-installer.exe"

# Download .NET Core installer
Invoke-WebRequest -Uri $dotnetInstallerUrl -OutFile $dotnetInstallerPath

# Install .NET Core
Start-Process -FilePath $dotnetInstallerPath -ArgumentList '/install /quiet /norestart' -Wait
Remove-Item -Path $dotnetInstallerPath -Force


#!/bin/bash

# Check if .NET Core is already installed
if ! [ -x "$(command -v dotnet)" ]; then
  echo ".NET Core is not installed. Installing..."
  wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
  sudo dpkg -i packages-microsoft-prod.deb
  sudo apt-get update
  sudo apt-get install -y apt-transport-https
  sudo apt-get update
  sudo apt-get install -y dotnet-sdk-3.1  # Replace with the desired version

  # Install Octopus Tentacle
  sudo apt-get install -y octopus-tentacle

  # Configure Octopus Tentacle (replace with your configuration)
  # Example: /opt/octopus/tentacle/Tentacle create-instance --config "/etc/octopus/Tentacle/tentacle.config" --console
  # Example: /opt/octopus/tentacle/Tentacle new-certificate --if-blank
  # Example: /opt/octopus/tentacle/Tentacle configure --noListen True --reset-trust
  # Example: /opt/octopus/tentacle/Tentacle register-worker --server "https://your-octopus-server.com" --apiKey "API-YOUR-API-KEY" --name "Worker-01" --publicHostName "worker01"
  # Example: /opt/octopus/tentacle/Tentacle service --install --start

else
  echo ".NET Core is already installed."
fi

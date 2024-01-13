#!/bin/bash

# Function to display error messages and exit
function error_exit {
    echo "Error: $1" >&2
    exit 1
}

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
    error_exit "This script must be run as root."
fi

# Enable the Extra Packages for Enterprise Linux (EPEL) repository
yum install -y epel-release || error_exit "Failed to enable EPEL repository."

# Install Node.js and npm
yum install -y nodejs npm || error_exit "Failed to install Node.js and npm."

# Install other prerequisites for React development
yum groupinstall -y "Development Tools" || error_exit "Failed to install development tools."
yum install -y python2 make gcc-c++ || error_exit "Failed to install additional prerequisites."

# Display installation success message
echo "Node.js, npm, and other prerequisites for React development have been successfully installed."
echo "Node.js version:"
node -v
echo "npm version:"
npm -v
echo "Python version:"
python2 -V

# If needed, update npm to the latest version
npm install -g npm@latest || error_exit "Failed to update npm to the latest version."

# Display updated npm version
echo "Updated npm version:"
npm -v

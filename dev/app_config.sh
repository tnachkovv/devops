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

# Install OpenJDK 17
yum install -y java-17-openjdk-devel || error_exit "Failed to install OpenJDK 17."

# Download and extract Apache Maven
MAVEN_VERSION="3.8.4"
MAVEN_URL="https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz"
MAVEN_HOME="/opt/maven"

mkdir -p "${MAVEN_HOME}" || error_exit "Failed to create Maven directory."

curl -fsSL "${MAVEN_URL}" | tar xz -C "${MAVEN_HOME}" --strip-components=1 || error_exit "Failed to download and extract Apache Maven."

# Add Maven and Java paths to environment variables
echo "export JAVA_HOME=/usr/lib/jvm/java-17-openjdk" >> /etc/profile.d/java.sh
echo "export MAVEN_HOME=${MAVEN_HOME}" >> /etc/profile.d/maven.sh
echo 'export PATH=${MAVEN_HOME}/bin:${PATH}' >> /etc/profile.d/maven.sh

# Reload environment variables
source /etc/profile.d/java.sh
source /etc/profile.d/maven.sh

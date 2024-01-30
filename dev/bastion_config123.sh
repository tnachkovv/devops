		#!/bin/bash
		##	ami-01b8fe779150ada4d for CentoOS9
		LOG_FILE="/tmp/setup_log.txt"

		# Redirect all commands and their outputs to a log file
		exec > >(tee -ia "$LOG_FILE")
		exec 2>&1

		# Exit script on error
		set -e

		# Update the system
		sudo yum update -y

		# Install common tools
		sudo yum install -y epel-release
		sudo yum install -y net-tools



		# Install Maven
		sudo yum install -y maven

		# Install Node.js and npm
		sudo yum install -y nodejs

		# Install Flyway
		sudo yum install -y flyway

		# Install PostgreSQL
		sudo yum install -y postgresql-server postgresql-contrib

		# Initialize the PostgreSQL database and start the service
		sudo postgresql-setup initdb
		sudo systemctl start postgresql
		sudo systemctl enable postgresql

		# Download and start Artifactory (adjust the version as needed)
		sudo mkdir -p /opt/artifactory
		wget -O /opt/artifactory/artifactory.zip https://jfrog.bintray.com/artifactory/jfrog-artifactory-cpp-ce-6.23.3.zip
		sudo unzip /opt/artifactory/artifactory.zip -d /opt/artifactory/
		sudo /opt/artifactory/jfrog-artifactory-cpp-ce-6.23.3/bin/artifactory.sh start

		# Install Git version 2.29
		sudo yum install -y https://packages.endpoint.com/rhel/7/os/x86_64/endpoint-repo-1.9-1.x86_64.rpm
		sudo yum install -y git-2.29.2-1.x86_64

		# Install certificates (adjust as needed)
		sudo yum install -y ca-certificates

		# Set up password for user ec2-user
		sudo bash -c 'echo "ec2-user:Secret123" | chpasswd'

		# Disable PasswordAuthentication and restart sshd (optional for security)
		sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
		sudo systemctl restart sshd


		# Set up repositories for OpenJDK 17 (adjust the URL as needed)
		sudo yum install -y java-21-openjdk
		java -version
		
		

		# Print versions for verification
		java -version
		mvn -version
		node -v
		npm -v
		flyway -v
		psql --version
		/opt/artifactory/jfrog-artifactory-cpp-ce-6.23.3.zip/bin/artifactory.sh --version
		git --version

		# Additional commands...

		# Your main script here

		# Example: Log the output of a command
		ls -l

		# Example: Log the output of another command
		echo "Hello from another command"

		sudo yum install httpd -y 
		sudo systemctl start httpd
		sudo systemctl enable httpd
		echo "<h1>This is $(hostname -f)</h1>" > /var/www/html/index.html
		# Continue with your script...

		# End of script

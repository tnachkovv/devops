import boto3
import subprocess
import shutil
import requests
import os
import time
import sys
import paramiko


# Set up log file to capture stdout and stderr
log_file_path = 'output.log'
sys.stdout = open(log_file_path, 'w')
sys.stderr = open(log_file_path, 'a')

# AWS credentials and region
aws_access_key = 'AKIA3T74XST7VP4UBI5S'
aws_secret_key = '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'
region = 'us-east-2'

# Octopus API Settings
octopus_url = 'https://test-task.octopus.app/'
octopus_api_key = 'API-BGRO5XSRFPWNFOENPXJ2OAUK7MOHSQNY'
project_name = 'dynamo-task-devops'
environment_name = 'Production'

# VPC and Subnet configuration
vpc_id = 'vpc-01e1cd14bea7c6458'
subnet_id = 'subnet-049363912ae4925a3'  # Replace with the actual Subnet ID within the VPC

# Paths
base_dir = os.path.abspath(os.path.dirname(__file__))
worker_app_path = os.path.join(base_dir, 'app')

# Step 1: Set up EC2 instances on AWS (Worker and Server)
ec2 = boto3.client('ec2', aws_access_key_id=aws_access_key, aws_secret_access_key=aws_secret_key, region_name=region)

# Function to allocate an Elastic IP address and associate it with an instance
def allocate_and_associate_elastic_ip(instance_id):
    # Allocate an Elastic IP address
    response = ec2.allocate_address()
    elastic_ip = response['PublicIp']
    print(f'Allocated Elastic IP address: {elastic_ip}')

    # Associate the Elastic IP address with the instance
    ec2.associate_address(InstanceId=instance_id, PublicIp=elastic_ip)
    print(f'Associated Elastic IP address {elastic_ip} with instance {instance_id}')

    return elastic_ip

# Function to get the Public DNS (IPv4) of an instance
def get_public_dns_ipv4(instance_id):
    response = ec2.describe_instances(InstanceIds=[instance_id])

    if response['Reservations']:
        instance = response['Reservations'][0]['Instances'][0]

        # Get the Public DNS (IPv4)
        public_dns_ipv4 = instance.get('PublicDnsName', 'N/A')

        return public_dns_ipv4

    return 'N/A'

# Function to run a command with elevated privileges using sudo
def run_with_sudo(command, cwd=None):
    try:
        result = subprocess.run(['sudo'] + command, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
        print("Command succeeded. Output:")
        print(result.stdout.decode('utf-8'))
    except subprocess.CalledProcessError as e:
        print(f"Command failed. Error output:")
        print(e.stderr.decode('utf-8'))

# Set up Worker instance
worker_instance = ec2.run_instances(
    ImageId='ami-00ba4cffa98b2aa4b',  # Worker instance AMI ID
    InstanceType='t2.micro',  # Instance type
    MinCount=1,
    MaxCount=1,
    KeyName='test-keypair1',  # Key pair name for SSH access
    TagSpecifications=[
        {
            'ResourceType': 'instance',
            'Tags': [{'Key': 'Name', 'Value': 'WorkerInstance'}]
        }
    ],
    SecurityGroupIds=['sg-04eac9ac1796852ea'],  # Security group IDs
    SubnetId=subnet_id,  # Specify the subnet within the VPC
)
# Get the worker instance ID
worker_instance_id = worker_instance['Instances'][0]['InstanceId']

# Wait for worker instance to reach the "running" state
while True:
    worker_instance = ec2.describe_instances(InstanceIds=[worker_instance_id])['Reservations'][0]['Instances'][0]

    if worker_instance['State']['Name'] == 'running':
        break  # Instance is running, exit the loop

    time.sleep(5)  # Wait for 5 seconds before checking again

# Now that the instance is running, associate the Elastic IP
worker_elastic_ip = allocate_and_associate_elastic_ip(worker_instance_id)

# Allocate Public DNS
worker_public_dns = ec2.describe_instances(InstanceIds=[worker_instance_id])['Reservations'][0]['Instances'][0][
    'PublicDnsName']

# Install .NET Core on Ubuntu using a Bash script
dotnet_install_script = """
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
"""
# Save the Bash script to a file and execute it
dotnet_install_script_path = os.path.join(base_dir, 'install_dotnet.sh')
with open(dotnet_install_script_path, 'w') as dotnet_install_file:
    dotnet_install_file.write(dotnet_install_script)

# SSH Key File (replace with the path to your key)
ssh_key_path = 'D:\\test-keypair1.pem'

# EC2 Instance Details
ec2_instance_ip = worker_elastic_ip
ec2_instance_username = 'ubuntu'

# Path to the local Bash script
local_script_path = 'install_dotnet.sh'

# Path to the remote directory on the EC2 instance
remote_dir = '/home/ubuntu/'  # Change this to the desired directory on your instance

print(f"Connecting to {ec2_instance_ip} as {ec2_instance_username} using key file {ssh_key_path}")
# Create an SSH client instance
ssh_client = paramiko.SSHClient()
ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

try:
    # Connect to the EC2 instance
    ssh_client.connect(ec2_instance_ip, username=ec2_instance_username, key_filename=ssh_key_path)

    # Use SFTP to copy the local script to the remote instance
    with ssh_client.open_sftp() as sftp:
        sftp.put(local_script_path, remote_dir + 'install_dotnet.sh')

    # Change the script permissions
    ssh_client.exec_command(f'chmod +x {remote_dir}install_dotnet.sh')

    # Execute the Bash script on the remote instance
    stdin, stdout, stderr = ssh_client.exec_command(f'{remote_dir}install_dotnet.sh')
    exit_status = stdout.channel.recv_exit_status()

    # Check the exit status to see if the script ran successfully
    if exit_status == 0:
        print('Bash script executed successfully on the EC2 instance.')
    else:
        print('Error executing Bash script on the EC2 instance:')
        print(stderr.read().decode('utf-8'))

finally:
    # Close the SSH connection
    ssh_client.close()


# Set up Server instance
server_instance = ec2.run_instances(
    ImageId='ami-00ba4cffa98b2aa4b',
    InstanceType='t2.micro',
    MinCount=1,
    MaxCount=1,
    KeyName='test-keypair1',
    TagSpecifications=[
        {
            'ResourceType': 'instance',
            'Tags': [{'Key': 'Name', 'Value': 'ServerInstance'}]
        }
    ],
    SecurityGroupIds=['sg-04eac9ac1796852ea'],
    SubnetId=subnet_id,  # Specify the subnet within the VPC
)
# Get the server instance ID immediately after launching
server_instance_id = server_instance['Instances'][0]['InstanceId']


# Wait for worker and server instances to reach the "running" state
while True:
    worker_instance = ec2.describe_instances(InstanceIds=[worker_instance_id])['Reservations'][0]['Instances'][0]
    server_instance = ec2.describe_instances(InstanceIds=[server_instance_id])['Reservations'][0]['Instances'][0]

    if worker_instance['State']['Name'] == 'running' and server_instance['State']['Name'] == 'running':
        break  # Both instances are running, exit the loop

    time.sleep(5)  # Wait for 5 seconds before checking again

worker_public_dns = ec2.describe_instances(InstanceIds=[worker_instance_id])['Reservations'][0]['Instances'][0][
    'PublicDnsName']
server_public_dns = ec2.describe_instances(InstanceIds=[server_instance_id])['Reservations'][0]['Instances'][0][
    'PublicDnsName']

# Allocate and associate Elastic IP
server_elastic_ip = allocate_and_associate_elastic_ip(server_instance_id)

# Allocate Public DNS
server_public_dns = ec2.describe_instances(InstanceIds=[server_instance_id])['Reservations'][0]['Instances'][0][
    'PublicDnsName']

# Step 2: Trigger Deployment in Octopus
headers = {
    'X-Octopus-ApiKey': octopus_api_key,
    'Content-Type': 'application/json'
}

payload = {
    'ProjectId': 'dynamo-project-new',
    'EnvironmentId': 'environments-YourEnvironmentId',
    'ChannelId': 'channels-YourChannelId',
    'SkipActions': []
}

response = requests.post(f'{octopus_url}/api/deployments', json=payload, headers=headers)
if response.status_code == 201:
    print('Deployment triggered successfully.')
else:
    print('Failed to trigger deployment.')

# Step 3: Build .NET Core App on Worker
subprocess.run(['dotnet', 'new', 'webapi', '-n', 'SimpleDotNetApp'], cwd=worker_app_path, shell=True)

# Step 4: Package Build on Worker
worker_build_output_path = os.path.join(worker_app_path, 'bin', 'Release', 'netcoreapp3.1', 'publish')
worker_package_path = os.path.join(base_dir, 'worker_package')
# Construct the path to the build output directory
worker_build_output_path = os.path.join(worker_app_path, 'bin', 'Release', 'netcoreapp3.1', 'publish')

# Debugging: Print the path to verify it's correct
print("Checking build output path:", worker_build_output_path)

# Verify if the path exists
if os.path.exists(worker_build_output_path):
    print("Build output path exists.")
else:
    print("Build output path does not exist.")

# Create the archive
shutil.make_archive(worker_package_path, 'zip', worker_build_output_path)

# Step 5: Deliver Build to Server via Automation (Octopus)
def deliver_build_to_server(package_path, octopus_url, octopus_api_key):
    headers = {
        'X-Octopus-ApiKey': octopus_api_key,
        'Content-Type': 'application/octet-stream',
    }

    with open(package_path, 'rb') as package_file:
        response = requests.post(f'{octopus_url}/api/packages/raw', headers=headers, data=package_file)
        if response.status_code == 201:
            print('Package uploaded successfully.')
            package_id = response.json()['Id']
            # Create a release using the package
            # Deploy the release to the server environment
        else:
            print('Failed to upload package.')

# Call the function to deliver the package to the server
deliver_build_to_server(worker_package_path + '.zip', octopus_url, octopus_api_key)

# Step 6: Create website and Deploy Build on Server via Automation (Octopus)
def create_website_and_deploy(octopus_url, octopus_api_key):
    headers = {
        'X-Octopus-ApiKey': octopus_api_key,
        'Content-Type': 'application/json',
    }

    # Create a new website using Octopus API
    website_payload = {
        'Name': 'MySimpleWebsite',
        'PhysicalPath': 'C:\\inetpub\\wwwroot\\MySimpleWebsite',  # Example physical path
        'Bindings': [
            {
                'Protocol': 'http',
                'IPAddress': '*',
                'Port': 80,
                'Hostname': 'mysimplewebsite.com'
            }
        ]
    }
    website_response = requests.post(f'{octopus_url}/api/websites', json=website_payload, headers=headers)
    if website_response.status_code == 201:
        print('Website created successfully.')
        website_id = website_response.json()['Id']

        # Deploy the package to the website using Octopus API
        deploy_payload = {
            'EnvironmentId': 'environments-YourEnvironmentId',
            'TenantId': None,
            'SpecificMachineIds': [],
            'ReleaseId': 'releases-YourReleaseId',  # Replace with actual release ID
            'SkipActions': []
        }
        deploy_response = requests.post(f'{octopus_url}/api/deployments', json=deploy_payload, headers=headers)
        if deploy_response.status_code == 201:
            print('Deployment to website successful.')
        else:
            print('Deployment to website failed.')
    else:
        print('Website creation failed.')

# Call the function to create website and deploy the build
create_website_and_deploy(octopus_url, octopus_api_key)

# Step 7: Validate Deployment
validation_url = f'http://{server_public_dns}/api/hello'
response = requests.get(validation_url)
if response.status_code == 200 and response.text == 'Hello from the .NET Core app!':
    print('Build is functional.')
else:
    print('Build validation failed.')

# Delay for 30 minutes before destroying the infrastructure
print('Waiting for 30 minutes before destroying infrastructure...')
time.sleep(1800)  # 30 minutes delay

# Terminate EC2 instances
ec2.terminate_instances(InstanceIds=[worker_instance_id, server_instance_id])
print('Infrastructure destroyed.')

# Clean up resources
ec2.terminate_instances(InstanceIds=[worker_instance_id, server_instance_id])

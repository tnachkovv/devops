import boto3
import subprocess
import shutil
import requests
import os
import time
import sys
import paramiko

log_file_path = 'output.log'  # Provide the path where you want to save the log file

# Redirect stdout and stderr to the log file
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
environment_name = 'Development'

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

def install_dotnet(worker_instance_id, ec2_instance_username, private_key_path):
    # Elastic IP address of the worker instance
    worker_elastic_ip = get_public_dns_ipv4(worker_instance_id)

    # Path to the local PowerShell script for .NET Core installation
    local_script_path = 'install_dotnet.ps1'

    # Path to the remote directory on the worker instance
    remote_dir = 'C:\\Temp\\'  # Change this to the desired directory on your Windows instance

    # Create an SSH client instance
    ssh_client = paramiko.SSHClient()
    ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    try:
        # Connect to the worker instance
        ssh_client.connect(worker_elastic_ip, username=ec2_instance_username, key_filename=private_key_path)

        # Use SFTP to copy the local script to the remote instance
        with ssh_client.open_sftp() as sftp:
            sftp.put(local_script_path, remote_dir + 'install_dotnet.ps1')

        # Execute the PowerShell script on the remote instance
        stdin, stdout, stderr = ssh_client.exec_command(
            f'powershell.exe -ExecutionPolicy Bypass -File {remote_dir}install_dotnet.ps1')
        exit_status = stdout.channel.recv_exit_status()

        # Check the exit status to see if the script ran successfully
        if exit_status == 0:
            print('.NET Core SDK installed successfully on the EC2 instance.')
        else:
            print('Error installing .NET Core SDK on the EC2 instance:')
            print(stderr.read().decode('utf-8'))

    finally:
        # Close the SSH connection
        ssh_client.close()

# Set up Worker instance
worker_instance = ec2.run_instances(
    ImageId='ami-0d1435d1563c37bbd',  # Worker instance AMI ID
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
    # Remove the NetworkInterfaces parameter
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

# Install Octopus Tentacle on the worker node
worker_private_ip = ec2.describe_instances(InstanceIds=[worker_instance_id])['Reservations'][0]['Instances'][0][
    'PrivateIpAddress']
subprocess.run(['Octopus.Tentacle.7.0.1.msi', '/quiet', '/norestart', f'APPLICATION_DIRECTORY={base_dir}',
                f'INSTALLER_AGENT=[ServerUrl={octopus_url};ApiKey={octopus_api_key}]', 'Roles=worker',
                f'PublicHostName={worker_public_dns}', f'PublicPort=10933', f'CommunicationMode=TentaclePassive',
                f'ListenIPAddress={worker_private_ip}'], cwd=base_dir, shell=True)

# Set up Server instance
server_instance = ec2.run_instances(
    ImageId='ami-0d1435d1563c37bbd',
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

# Call the function to install .NET Core SDK on the worker node
install_dotnet(worker_instance_id, ec2_instance_username, private_key_path)

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

# After allocating and associating the Elastic IP for the server instance, you can retrieve its public IP address like this:
server_dns_or_ip = ec2.describe_addresses(Filters=[{'Name': 'instance-id', 'Values': [server_instance_id]}])['Addresses'][0]['PublicIp']

# Step 5: Deliver Build to Server via Octopus
def deliver_build_to_server(package_path, octopus_url, octopus_api_key, server_dns_or_ip):
    headers = {
        'X-Octopus-ApiKey': octopus_api_key,
        'Content-Type': 'application/octet-stream',
    }

    # Construct the URL to upload the package to the server
    upload_url = f'{octopus_url}/api/packages/raw?server={server_dns_or_ip}'

    with open(package_path, 'rb') as package_file:
        response = requests.post(upload_url, headers=headers, data=package_file)
        if response.status_code == 201:
            print('Package uploaded successfully.')
            package_id = response.json()['Id']

            # Create a release using the uploaded package
            release_payload = {
                'ProjectId': 'your-project-id',  # Replace with your actual project ID
                'Version': '1.0.0',  # Replace with the desired version
                'PackageReference': {
                    'PackageId': package_id,
                    'PackageVersion': '1.0.0'  # Replace with the package version
                }
            }

            release_response = requests.post(f'{octopus_url}/api/releases', json=release_payload, headers=headers)
            if release_response.status_code == 201:
                print('Release created successfully.')

                # Deploy the release to the server environment
                deploy_payload = {
                    'EnvironmentId': 'your-environment-id',  # Replace with your actual environment ID
                    'ReleaseId': release_response.json()['Id']
                }
                deploy_response = requests.post(f'{octopus_url}/api/deployments', json=deploy_payload, headers=headers)
                if deploy_response.status_code == 201:
                    print('Deployment to server environment initiated.')
                else:
                    print('Deployment to server environment failed.')
            else:
                print('Failed to create release.')
        else:
            print('Failed to upload package.')

# Call the function to deliver the package to the server
deliver_build_to_server(worker_package_path + '.zip', octopus_url, octopus_api_key, server_dns_or_ip)

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

terraform {
  required_providers {
    aws = {
      source  = "registry.terraform.io/hashicorp/aws"
      version = "4.0.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "rhel_9-3" {
  most_recent = "true"
//  id = "ami-023c11a32b0207432"

  filter {
    name   = "name"
    values = ["RHEL-9.3.0_HVM-20231101-x86_64-5-Hourly2-GP2"]
  }
  owners = ["309956199498"]
}

resource "aws_vpc" "ep_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  tags = {
    Name = "ep_vpc"
  }
}

resource "aws_internet_gateway" "ep_igw" {
  vpc_id = aws_vpc.ep_vpc.id
  tags = {
    Name = "ep_igw"
  }
}

resource "aws_subnet" "ep_public_subnet" {
  count             = var.subnet_count.public
  vpc_id            = aws_vpc.ep_vpc.id
  cidr_block        = var.public_subnet_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "ep_public_subnet_${count.index}"
  }
}

resource "aws_subnet" "ep_private_web_subnet" {
  count             = var.subnet_count.private
  vpc_id            = aws_vpc.ep_vpc.id
  cidr_block        = var.private_subnet_web_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "ep_private_web_subnet_${count.index}"
  }
}


resource "aws_subnet" "ep_private_app_subnet" {
  count             = var.subnet_count.private
  vpc_id            = aws_vpc.ep_vpc.id
  cidr_block        = var.private_subnet_app_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "ep_private_app_subnet_${count.index}"
  }
}

resource "aws_subnet" "ep_private_db_subnet" {
  count             = var.subnet_count.private
  vpc_id            = aws_vpc.ep_vpc.id
  cidr_block        = var.private_subnet_db_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "ep_private_db_subnet_${count.index}"
  }
}

resource "aws_route_table" "ep_public_rt" {
  vpc_id = aws_vpc.ep_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ep_igw.id
  }
}

resource "aws_route_table_association" "public" {
  count          = var.subnet_count.public
  route_table_id = aws_route_table.ep_public_rt.id
  subnet_id      = 	aws_subnet.ep_public_subnet[count.index].id
}

resource "aws_route_table" "ep_private_rt" {
  vpc_id = aws_vpc.ep_vpc.id
}

resource "aws_route_table" "ep_private_rt_db" {
  vpc_id = aws_vpc.ep_vpc.id
}


resource "aws_route_table_association" "private_web" {
  count          = var.subnet_count.private
  route_table_id = aws_route_table.ep_private_rt.id
  subnet_id      = aws_subnet.ep_private_web_subnet[count.index].id
}


resource "aws_route_table_association" "private_app" {
  count          = var.subnet_count.private
  route_table_id = aws_route_table.ep_private_rt.id
  subnet_id      = aws_subnet.ep_private_app_subnet[count.index].id
}

resource "aws_route_table_association" "private_db" {
  count          = var.subnet_count.private
  route_table_id = aws_route_table.ep_private_rt_db.id
  subnet_id      = aws_subnet.ep_private_db_subnet[count.index].id
}

resource "aws_security_group" "ep_web_sg" {
  name        = "ep_web_sg"
  description = "Security group for web server (presentation layer)"
  vpc_id      = aws_vpc.ep_vpc.id

  ingress {
    description = "Allow all traffic through HTTPS"
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow all traffic through HTTP"
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH from my bastion host"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "ep_app_sg" {
  name        = "ep_app_sg"
  description = "Security group for app server (application layer)"
  vpc_id      = aws_vpc.ep_vpc.id

  ingress {
    description = "Allow all traffic through HTTPS"
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow all traffic through HTTP"
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    description = "Allow all traffic through HTTP"
    from_port   = "8000"
    to_port     = "8000"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH from my bastion host"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "ep_app_sg"
  }
}

resource "aws_security_group" "ep_bastion_sg" {
  name        = "ep_bastion_sg"
  description = "Security group for test web servers"
  vpc_id      = aws_vpc.ep_vpc.id

  ingress {
    description = "Allow all traffic through HTTP"
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow all traffic through HTTP"
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH from my local computer"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "ep_bastion_sg"
  }
}

resource "aws_security_group" "ep_db_sg" {
  name        = "ep_db_sg"
  description = "Security group for ep postgres database"
  vpc_id      = aws_vpc.ep_vpc.id
  ingress {
    description     = "Allow Postgres traffic only from the application sg"
    from_port       = "5432"
    to_port         = "5432"
    protocol        = "tcp"
    security_groups = [aws_security_group.ep_app_sg.id]
  }
  tags = {
    Name = "ep_db_sg"
  }
}

resource "aws_db_subnet_group" "ep_db_subnet_group" {
  name        = "ep_db_subnet_group"
  description = "DB subnet group for test"
  subnet_ids  = [for subnet in aws_subnet.ep_private_db_subnet : subnet.id]
}

resource "aws_db_instance" "ep_database_dev" {
  allocated_storage      = var.settings.database.allocated_storage
  engine                 = var.settings.database.engine
  instance_class         = var.settings.database.instance_class
  db_name                = var.settings.database.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.ep_db_subnet_group.id
  vpc_security_group_ids = [aws_security_group.ep_db_sg.id]
  skip_final_snapshot    = var.settings.database.skip_final_snapshot
}

resource "aws_instance" "ep_app_dev" {
  count                  = var.settings.web_app.count
  ami                    = data.aws_ami.rhel_9-3.id
  instance_type          = var.settings.web_app.instance_type
  subnet_id              = aws_subnet.ep_private_app_subnet[count.index].id
  key_name               = "web-kp"
  vpc_security_group_ids = [aws_security_group.ep_web_sg.id]
  user_data = file("app_config.sh")

  tags = {
    Name = "ep-app-dev-${count.index+1}"
  }
}

resource "aws_instance" "ep_web" {
  count                  = var.settings.web_app.count
  ami                    = data.aws_ami.rhel_9-3.id
  instance_type          = var.settings.web_app.instance_type
  subnet_id              = aws_subnet.ep_private_web_subnet[count.index].id
  key_name               = "web-kp"
  vpc_security_group_ids = [aws_security_group.ep_web_sg.id]
  user_data = file("web_config.sh")

  tags = {
    Name = "ep-web-dev-${count.index+1}"
  }
}

resource "aws_instance" "ep_bastion" {
  count                  = var.settings.bastion.count
  ami                    = data.aws_ami.rhel_9-3.id
  instance_type          = var.settings.bastion.instance_type
  subnet_id              = aws_subnet.ep_public_subnet[count.index].id
  key_name               = "web-kp"
  vpc_security_group_ids = [aws_security_group.ep_bastion_sg.id]
  user_data = file("bastion_config.sh")

  tags = {
    Name = "ep-bastion-dev-${count.index+1}"
  }
}


resource "aws_eip" "ep_bastion_eip" {
  count    = var.settings.bastion.count
  instance = aws_instance.ep_bastion[count.index].id
  vpc      = true
  tags = {
    Name = "ep-web-eip-${count.index+1}"
  }
}

resource "aws_eip" "ep_nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "ep_nat_gateway" {
  allocation_id = aws_eip.ep_nat_eip.id
  subnet_id     = aws_subnet.ep_public_subnet[0].id
}

resource "aws_route" "ep_private_route" {
  route_table_id         = aws_route_table.ep_private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ep_nat_gateway.id
}

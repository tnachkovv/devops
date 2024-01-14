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

//resource "aws_vpc" "ep_vpc" {
//  cidr_block           = var.vpc_cidr_block
//  enable_dns_hostnames = true
//  tags = {
//    Name = "ep_vpc"
//  }
//}

//resource "aws_internet_gateway" "ep_igw" {
//  vpc_id = aws_vpc.ep_vpc.id
//  tags = {
//    Name = "ep_igw"
//  }
//}

//resource "aws_subnet" "ep_public_subnet" {
//  count             = var.subnet_count.public
//  vpc_id            = aws_vpc.ep_vpc.id
//  cidr_block        = var.public_subnet_cidr_blocks[count.index]
//  availability_zone = data.aws_availability_zones.available.names[count.index]
//  tags = {
//    Name = "ep_public_subnet_${count.index}"
//  }
//}

//resource "aws_subnet" "ep_private_subnet" {
//  count             = var.subnet_count.private
//  vpc_id            = aws_vpc.ep_vpc.id
//  cidr_block        = var.private_subnet_cidr_blocks[count.index]
//  availability_zone = data.aws_availability_zones.available.names[count.index]
//  tags = {
//    Name = "ep_private_subnet_${count.index}"
//  }
//}

//resource "aws_route_table" "ep_public_rt" {
//  vpc_id = aws_vpc.ep_vpc.id
//  route {
//    cidr_block = "0.0.0.0/0"
//    gateway_id = aws_internet_gateway.ep_igw.id
//  }
//}

//resource "aws_route_table_association" "public" {
//  count          = var.subnet_count.public
//  route_table_id = aws_route_table.ep_public_rt.id
//  subnet_id      = 	aws_subnet.ep_public_subnet[count.index].id
//}
//
//resource "aws_route_table" "ep_private_rt" {
//  vpc_id = aws_vpc.ep_vpc.id
//}
//
//resource "aws_route_table_association" "private" {
//  count          = var.subnet_count.private
//  route_table_id = aws_route_table.ep_private_rt.id
//  subnet_id      = aws_subnet.ep_private_subnet[count.index].id
//}
//
//resource "aws_security_group" "ep_web_sg" {
//  name        = "ep_web_sg"
//  description = "Security group for web server (presentation layer)"
//  vpc_id      = aws_vpc.ep_vpc.id
//
//  ingress {
//    description = "Allow all traffic through HTTPS"
//    from_port   = "443"
//    to_port     = "443"
//    protocol    = "tcp"
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//
//  ingress {
//    description = "Allow all traffic through HTTP"
//    from_port   = "80"
//    to_port     = "80"
//    protocol    = "tcp"
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//
//  ingress {
//    description = "Allow SSH from my bastion host"
//    from_port   = 22
//    to_port     = 22
//    protocol    = "tcp"
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//
//  egress {
//    description = "Allow all outbound traffic"
//    from_port   = 0
//    to_port     = 0
//    protocol    = "-1"
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//}
//
//
//resource "aws_security_group" "ep_app_sg" {
//  name        = "ep_app_sg"
//  description = "Security group for app server (application layer)"
//  vpc_id      = aws_vpc.ep_vpc.id
//
//  ingress {
//    description = "Allow all traffic through HTTPS"
//    from_port   = "443"
//    to_port     = "443"
//    protocol    = "tcp"
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//
//  ingress {
//    description = "Allow all traffic through HTTP"
//    from_port   = "80"
//    to_port     = "80"
//    protocol    = "tcp"
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//
//  ingress {
//    description = "Allow SSH from my bastion host"
//    from_port   = 22
//    to_port     = 22
//    protocol    = "tcp"
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//
//  egress {
//    description = "Allow all outbound traffic"
//    from_port   = 0
//    to_port     = 0
//    protocol    = "-1"
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//  tags = {
//    Name = "ep_app_sg"
//  }
//}
//
//resource "aws_security_group" "ep_bastion_sg" {
//  name        = "ep_bastion_sg"
//  description = "Security group for test web servers"
//  vpc_id      = aws_vpc.ep_vpc.id
//
//  ingress {
//    description = "Allow all traffic through HTTP"
//    from_port   = "443"
//    to_port     = "443"
//    protocol    = "tcp"
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//
//  ingress {
//    description = "Allow all traffic through HTTP"
//    from_port   = "80"
//    to_port     = "80"
//    protocol    = "tcp"
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//
//  ingress {
//    description = "Allow SSH from my local computer"
//    from_port   = 22
//    to_port     = 22
//    protocol    = "tcp"
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//
//  egress {
//    description = "Allow all outbound traffic"
//    from_port   = 0
//    to_port     = 0
//    protocol    = "-1"
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//  tags = {
//    Name = "ep_bastion_sg"
//  }
//}
//
//resource "aws_security_group" "ep_db_sg" {
//  name        = "ep_db_sg"
//  description = "Security group for ep postgres database"
//  vpc_id      = aws_vpc.ep_vpc.id
//  ingress {
//    description     = "Allow Postgres traffic from only the application sg"
//    from_port       = "5432"
//    to_port         = "5432"
//    protocol        = "tcp"
//    security_groups = [aws_security_group.ep_app_sg.id]
//  }
//  tags = {
//    Name = "ep_db_sg"
//  }
//}

resource "aws_db_instance" "ep_database_qa" {
  allocated_storage      = var.settings.database.allocated_storage
  engine                 = var.settings.database.engine
  instance_class         = var.settings.database.instance_class
  db_name                = var.settings.database.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = "ep_db_subnet_group"
  vpc_security_group_ids = ["sg-07fef310972a5f24c"]
  skip_final_snapshot    = var.settings.database.skip_final_snapshot
}

resource "aws_instance" "ep_app_qa" {
  count                  = var.settings.web_app.count
  ami                    = data.aws_ami.rhel_9-3.id
  instance_type          = var.settings.web_app.instance_type
  subnet_id              = count.index % 2 == 0 ? "subnet-092fe846f2a74974f" : "subnet-0f7f34a189e0b7b74"
  key_name               = "web-kp"
  vpc_security_group_ids = ["sg-0a37728ce99634965"]
  user_data = file("app_config.sh")

  tags = {
    Name = "ep-app-qa-${count.index+1}"
  }
}

resource "aws_instance" "ep_web_qa" {
  count                  = var.settings.web_app.count
  ami                    = data.aws_ami.rhel_9-3.id
  instance_type          = var.settings.web_app.instance_type
  subnet_id              = count.index % 2 == 0 ? "subnet-092fe846f2a74974f" : "subnet-0f7f34a189e0b7b74"
  key_name               = "web-kp"
  vpc_security_group_ids = ["sg-0a37728ce99634965"]
  user_data = file("web_config.sh")

  tags = {
    Name = "ep-web-qa-${count.index+1}"
  }
}

//resource "aws_instance" "ep_bastion" {
//  count                  = var.settings.bastion.count
//  ami                    = data.aws_ami.rhel_9-3.id
//  instance_type          = var.settings.bastion.instance_type
//  subnet_id              = aws_subnet.ep_public_subnet[count.index].id
//  key_name               = "web-kp"
//  vpc_security_group_ids = [aws_security_group.ep_bastion_sg.id]
//  user_data = file("bastion_config.sh")
//
//  tags = {
//    Name = "ep_bastion_dev${count.index}"
//  }
//}


//resource "aws_eip" "ep_bastion_eip" {
//  count    = var.settings.bastion.count
//  instance = aws_instance.ep_bastion[count.index].id
//  vpc      = true
//  tags = {
//    Name = "ep_web_eip_${count.index}"
//  }
//}

//resource "aws_eip" "ep_nat_eip" {
//  vpc = true
//}
//
//resource "aws_nat_gateway" "ep_nat_gateway" {
//  allocation_id = aws_eip.ep_nat_eip.id
//  subnet_id     = aws_subnet.ep_public_subnet[0].id
//}
//
//resource "aws_route" "ep_private_route" {
//  route_table_id         = aws_route_table.ep_private_rt.id
//  destination_cidr_block = "0.0.0.0/0"
//  nat_gateway_id         = aws_nat_gateway.ep_nat_gateway.id
//}


//# Define a network interface for your web instances
//resource "aws_network_interface" "ep_web_network_interface_qa" {
//  subnet_id          = "subnet-052b91a2280100dda"
//  security_group_ids = ["sg-0a37728ce99634965"]
//}

# Define a Launch Template for your web instances
resource "aws_launch_template" "ep_web_template_qa" {
  name = "ep_web_template_qa"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
      volume_type = "gp2"
    }
  }

  image_id = "ami-0f4f08cbbf1cf0662"
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "ep_web_template_qa"
    }
  }
  instance_type = "t2.micro"

  user_data = <<-EOF
              #!/bin/bash
              echo "User data script executed." >> /var/log/user_data.log
              # Your additional initialization steps here
              EOF
}

# Define an Auto Scaling Group for your web instances
resource "aws_autoscaling_group" "ep_autoscaling_group_web_qa" {
  desired_capacity     = 2
  max_size             = 5
  min_size             = 2
  vpc_zone_identifier = ["subnet-092fe846f2a74974f", "subnet-0f7f34a189e0b7b74"]

  launch_template {
    id      = aws_launch_template.ep_web_template_qa.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ep_autoscaling_group_web_qa"
    propagate_at_launch = true
  }

  health_check_type          = "EC2"
  health_check_grace_period  = 300
  force_delete               = true
}


//# Define a network interface for your application instances
//resource "aws_network_interface" "ep_app_network_interface_qa" {
//  subnet_id          = "subnet-092fe846f2a74974f"
//  security_group_ids = ["sg-0a37728ce99634965"]
//}

# Define a Launch Template for your application instances
resource "aws_launch_template" "ep_app_template_qa" {
  name = "ep_app_template_qa"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
      volume_type = "gp2"
    }
  }

  image_id = "ami-016b43236f2516b75"
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "ep_app_template_qa"
    }
  }
    instance_type = "t2.micro"

    user_data = <<-EOF
              #!/bin/bash
              echo "User data script executed." >> /var/log/user_data.log
              # Your additional initialization steps here
              EOF
}
# Define an Auto Scaling Group for app instances
resource "aws_autoscaling_group" "ep_autoscaling_group_app_qa" {
  desired_capacity     = 2
  max_size             = 5
  min_size             = 2
  vpc_zone_identifier = ["subnet-092fe846f2a74974f", "subnet-0f7f34a189e0b7b74"]

  launch_template {
    id      = aws_launch_template.ep_app_template_qa.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ep_autoscaling_group_app_qa"
    propagate_at_launch = true
  }

  health_check_type          = "EC2"
  health_check_grace_period  = 300
  force_delete               = true
}


####LOAD BALANCING#####

# Define a security group for your load balancer
resource "aws_security_group" "ext_lb_sg_qa" {
  name        = "ext-lb-sg-qa"
  description = "Security group for load balancer"

  # Define your security group rules here as needed
  # For example, allow incoming traffic on ports 80 and 443
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define a target group for your web servers
resource "aws_lb_target_group" "web_target_group_qa" {
  name     = "web-target-group-qa"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-07f1dbbe3a33737af"

  health_check {
    interval            = 30
    path                = "/"
    port                = "80"
    protocol            = "HTTP"
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Define an Elastic Load Balancer for your web servers
resource "aws_lb" "web_lb" {
  name               = "ext_web_lb_qa"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ext_lb_sg_qa.id]

  enable_deletion_protection = false

  enable_cross_zone_load_balancing = true

  subnets = ["subnet-052b91a2280100dda", "subnet-0db548a08151d2260"] # These are the public subnets

  enable_http2 = true

  tags = {
    Name = "ext_web_lb_qa"
  }
}

# Define a listener for your web server load balancer
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.web_target_group_qa.arn
    type             = "forward"
  }
}


# Define a security group for your internal load balancer
resource "aws_security_group" "int_lb_sg_qa" {
  name        = "int_lb_sg_qa"
  description = "Security group for load balancer"

  # Define your security group rules here as needed
  # For example, allow incoming traffic on ports 80 and 443
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group_attachment" "ep_web_lb_attachment_qa" {
  target_group_arn = aws_lb_target_group.web_target_group_qa.arn
  count = length(aws_instance.ep_web_qa)
  target_id = aws_instance.ep_web_qa[count.index].id
  port             = 80
}


# Define an Elastic Load Balancer for your application servers
resource "aws_lb" "app_lb" {
  name               = "int_app_lb_qa"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.int_lb_sg_qa.id]
  enable_deletion_protection = false
  enable_cross_zone_load_balancing = true
  subnets = ["subnet-092fe846f2a74974f", "subnet-0f7f34a189e0b7b74"] # These the private subnets
  enable_http2 = true
  tags = {
    Name = "int_app_lb_qa"
  }
}

# Define a target group for your application servers
resource "aws_lb_target_group" "app_target_group_qa" {
  name     = "app-target-group"
  port     = 8000 # Change to your desired application server port
  protocol = "HTTP"
  vpc_id   = "vpc-07f1dbbe3a33737af"

  health_check {
    interval            = 30
    path                = "/"
    port                = "8000"
    protocol            = "HTTP"
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Define a listener for your application server load balancer
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 8000
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.app_target_group_qa.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group_attachment" "ep_app_lb_attachment_qa" {
  target_group_arn = aws_lb_target_group.app_target_group_qa.arn
  count = length(aws_instance.ep_app_qa)
  target_id = aws_instance.ep_app_qa[count.index].id
  port             = 8000
}

resource "aws_cloudwatch_metric_alarm" "requests_alarm" {
  alarm_name          = "HighRequestCountAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "RequestCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1000"
  alarm_description  = "Alarm when the total number of requests exceeds 1000"
}
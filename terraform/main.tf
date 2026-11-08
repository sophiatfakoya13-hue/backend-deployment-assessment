terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}


resource "aws_vpc" "startuptech_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "startuptech-vpc"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}


resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.startuptech_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "startuptech-public-subnet-1"
  }
}


resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.startuptech_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "startuptech-public-subnet-2"
  }
}


resource "aws_subnet" "private_1" {
  vpc_id                  = aws_vpc.startuptech_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "startuptech-private-subnet-1"
  }
}


resource "aws_subnet" "private_2" {
  vpc_id                  = aws_vpc.startuptech_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "startuptech-private-subnet-2"
  }
}


resource "aws_internet_gateway" "startuptech_igw" {
  vpc_id = aws_vpc.startuptech_vpc.id

  tags = {
    Name = "startuptech-igw"
  }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.startuptech_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.startuptech_igw.id
  }

  tags = {
    Name = "startuptech-public-route-table"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}


resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "startuptech-nat-eip"
  }
}


resource "aws_nat_gateway" "startuptech_nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id

  tags = {
    Name = "startuptech-nat-gateway"
  }

  depends_on = [aws_internet_gateway.startuptech_igw]
}


resource "aws_route_table" "private" {
  vpc_id = aws_vpc.startuptech_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.startuptech_nat.id
  }

  tags = {
    Name = "startuptech-private-route-table"
  }
}


resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}


resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}



resource "aws_security_group" "alb_sg" {
  name        = "startuptech-alb-sg"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.startuptech_vpc.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "startuptech-alb-sg"
  }
}


resource "aws_security_group" "bastion_sg" {
  name        = "startuptech-bastion-sg"
  description = "Allow SSH from my current IP only"
  vpc_id      = aws_vpc.startuptech_vpc.id

  ingress {
    description = "SSH from my current IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "startuptech-bastion-sg"
  }
}


resource "aws_security_group" "backend_sg" {
  name        = "startuptech-backend-sg"
  description = "Allow traffic from ALB and Bastion only"
  vpc_id      = aws_vpc.startuptech_vpc.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "startuptech-backend-sg"
  }
}


resource "aws_security_group" "mongodb_sg" {
  name        = "startuptech-mongodb-sg"
  description = "Allow MongoDB access from backend only"
  vpc_id      = aws_vpc.startuptech_vpc.id

  ingress {
    description     = "MongoDB from backend"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "startuptech-mongodb-sg"
  }
}


data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_1.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  key_name                    = var.ssh_key_name
  associate_public_ip_address = true

  tags = {
    Name = "startuptech-bastion"
  }
}


resource "aws_eip" "bastion" {
  domain   = "vpc"
  instance = aws_instance.bastion.id

  tags = {
    Name = "startuptech-bastion-eip"
  }
}


resource "aws_instance" "backend" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_1.id
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  key_name               = var.ssh_key_name

  user_data = file("${path.module}/user_data/backend_setup.sh")

  tags = {
    Name = "startuptech-backend"
  }
}


resource "aws_instance" "mongodb" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_2.id
  vpc_security_group_ids = [aws_security_group.mongodb_sg.id]
  key_name               = var.ssh_key_name

  user_data = file("${path.module}/user_data/mongodb_setup.sh")

  tags = {
    Name = "startuptech-mongodb"
  }
}


resource "aws_lb" "startuptech_alb" {
  name               = "startuptech-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]

  subnets = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]

  tags = {
    Name = "startuptech-alb"
  }
}


resource "aws_lb_target_group" "backend_tg" {
  name     = "startuptech-backend-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.startuptech_vpc.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "startuptech-backend-tg"
  }
}


resource "aws_lb_target_group_attachment" "backend_attachment" {
  target_group_arn = aws_lb_target_group.backend_tg.arn
  target_id        = aws_instance.backend.id
  port             = 8080
}


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.startuptech_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}


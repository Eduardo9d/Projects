terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -------------------------
# Get current public IP for security group restrictions
# -------------------------
data "http" "my_ip" {
  url = "https://ipv4.icanhazip.com"
}

# -------------------------
# VPC
# -------------------------
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "terraform-vpc"
  }
}

# -------------------------
# Subnet
# -------------------------
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# -------------------------
# Internet Gateway
# -------------------------
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "terraform-igw"
  }
}

# -------------------------
# Route Table
# -------------------------
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.rt.id
}

# -------------------------
# Security Group
# -------------------------
resource "aws_security_group" "sg" {
  name        = "terraform-sg"
  description = "Allow SSH and Kubernetes API from current IP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from current IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = concat(["${chomp(data.http.my_ip.response_body)}/32"], var.allowed_ips)
  }
  ingress {
    description = "Kubernetes API Server from current IP"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = concat(["${chomp(data.http.my_ip.response_body)}/32"], var.allowed_ips)
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------
# EC2 Instance
# -------------------------
resource "aws_instance" "ec2" {
  ami           = var.ec2_ami
  instance_type = var.instance_type

  key_name = var.key_name   # 🔥 MUST exist

  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.sg.id]

  user_data = <<-EOF
#! /bin/bash
set -e
echo "🚀 Installing Minikube..."

curl -LO \
https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64

sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64

sudo usermod -aG docker $USER && newgrp docker 

minikube start --driver=virtualbox

minikube status

echo "🚀 Minikube installation complete!"
# minikube stop

# minikube delete

sudo apt install bash-completion

source /etc/bash_completion

source <(minikube completion bash)

# If needed, also run the following command:

minikube completion bash | sudo tee /etc/bash_completion.d/minikube

              EOF

  tags = {
    Name = "Kubernetes-Master"
  }
}
# -------------------------
# Private Subnets for RDS (Multi-AZ)
# -------------------------
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/25"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "private-subnet-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.128/25"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "private-subnet-b"
  }
}

# -------------------------
# DB Subnet Group
# -------------------------
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "main-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "Main DB subnet group"
  }
}

# -------------------------
# Database Security Group
# -------------------------
resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  description = "Allow MySQL inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from VPC"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.sg.id]  # Allow from EC2 SG only
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg"
  }
}

# -------------------------
# Database (RDS)
# -------------------------
resource "aws_db_instance" "db" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = var.db.name
  username               = var.db.username
  password               = var.db.password
  parameter_group_name   = "default.mysql8.0"
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true

  tags = {
    Name = "terraform-db"
  }
}
# -------------------------
# S3 Bucket
# -------------------------
resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name

  tags = {
    Name = "terraform-bucket"
  }
}


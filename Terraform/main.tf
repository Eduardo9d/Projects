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
  description = "Allow SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from specific IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # TODO: Restrict to your IP range for security
  }
  ingress {
    description = "Kubernetes API Server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # TODO: Restrict to your IP range for security
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
              set -e

              echo "🚀 Updating system..."
              sudo apt update && sudo apt upgrade -y

              echo "🚀 Disabling swap..."
              sudo swapoff -a
              sudo sed -i '/ swap / s/^/#/' /etc/fstab

              echo "🚀 Installing dependencies..."
              sudo apt install -y apt-transport-https ca-certificates curl gpg

              echo "🚀 Installing containerd..."
              sudo apt install -y containerd

              sudo mkdir -p /etc/containerd
              containerd config default | sudo tee /etc/containerd/config.toml
              sudo systemctl restart containerd
              sudo systemctl enable containerd

              echo "🚀 Adding Kubernetes repo..."
              sudo mkdir -p /etc/apt/keyrings

              curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key \
              | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes.gpg

              echo "deb [signed-by=/etc/apt/keyrings/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" \
              | sudo tee /etc/apt/sources.list.d/kubernetes.list

              echo "🚀 Installing Kubernetes tools..."
              sudo apt update
              sudo apt install -y kubelet kubeadm kubectl
              sudo apt-mark hold kubelet kubeadm kubectl
              # Load necessary kernel modules and set sysctl params for Kubernetes networking
              echo "🚀 Loading kernel modules..."
              sudo modprobe br_netfilter
              sudo modprobe overlay
              # Enable required sysctl params, persist across reboots
              echo "🚀 Configuring sysctl for Kubernetes..."
              cat <<'INNER_EOF' | sudo tee /etc/sysctl.d/kubernetes.conf
              net.bridge.bridge-nf-call-ip6tables = 1
              net.bridge.bridge-nf-call-iptables = 1
              net.ipv4.ip_forward = 1
              INNER_EOF
              # Apply sysctl params without reboot
              sudo sysctl --system

              echo "🚀 Initializing cluster..."
              sudo kubeadm init --pod-network-cidr=10.244.0.0/16

              echo "🚀 Configuring kubectl..."
              mkdir -p $HOME/.kube
              sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
              sudo chown $(id -u):$(id -g) $HOME/.kube/config

              echo "🚀 Installing Flannel network..."
              kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

              echo "🚀 Allow scheduling on master (single node setup)"
              kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

              echo "🎉 Kubernetes cluster is ready!"
              kubectl get nodes
              EOF

  tags = {
    Name = "Kubernetes-Master"
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


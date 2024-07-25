# Fetching the AWS account ID
data "aws_caller_identity" "current" {}

# VPC (Virtual Private Cloud)
# This resource creates a VPC with the specified CIDR block
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "main-vpc"
  }
}

# Public Subnet 1
# This resource creates the first public subnet within the VPC
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr1
  availability_zone       = var.availability_zone1
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-1"
  }
}

# Public Subnet 2
# This resource creates the second public subnet within the VPC
resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr2
  availability_zone       = var.availability_zone2
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-2"
  }
}

# Admin Subnet
# This resource creates the admin subnet within the VPC
resource "aws_subnet" "admin" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.admin_subnet_cidr
  map_public_ip_on_launch = true
  tags = {
    Name = "admin-subnet"
  }
}

# Internet Gateway
# This resource creates an Internet Gateway for the VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}

# Route Table
# This resource creates a route table for the VPC
resource "aws_route_table" "routetable" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "main-route-table"
  }
}

# Route Table Association for Public Subnet 1
# This resource associates the route table with the first public subnet
resource "aws_route_table_association" "public_association1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.routetable.id
}

# Route Table Association for Public Subnet 2
# This resource associates the route table with the second public subnet
resource "aws_route_table_association" "public_association2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.routetable.id
}

# Route Table Association for Admin Subnet
# This resource associates the route table with the admin subnet
resource "aws_route_table_association" "admin_association" {
  subnet_id      = aws_subnet.admin.id
  route_table_id = aws_route_table.routetable.id
}

# Security Group for ELB
# This resource creates a security group for the Elastic Load Balancer
resource "aws_security_group" "elb" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "elb-security-group"
  }
}

# Security Group for Instances
# This resource creates a security group for the instances in the VPC
resource "aws_security_group" "instance" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH access from anywhere"
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow access to Kubernetes API server"
  }

  ingress {
    from_port   = 3100
    to_port     = 3100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow access to Loki"
  }

  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow access to etcd"
  }

  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow access to kubelet"
  }

  # Calico ports
  ingress {
    from_port   = 179
    to_port     = 179
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow BGP protocol for Calico"
  }

  ingress {
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow VXLAN for Calico"
  }

  ingress {
    from_port   = 4
    to_port     = 4
    protocol    = "4"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow IP-in-IP for Calico"
  }

  ingress {
    from_port   = 8285
    to_port     = 8285
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow IP-in-IP encapsulated packets for Calico"
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow access to Node Exporter"
  }

  ingress {
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow VXLAN for Flannel"
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow access to NodePort services"
  }

  ingress {
    from_port   = 500
    to_port     = 500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow IKE traffic for VPN"
  }

  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow OpenVPN traffic"
  }

  ingress {
    from_port   = 4500
    to_port     = 4500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow IPsec NAT traversal traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "instance-security-group"
  }
}

# Load Balancer Target Group
# This resource creates a target group for the Kubernetes cluster
resource "aws_lb_target_group" "k8s_target_group" {
  name        = "k8s-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"
  health_check {
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 2
  }
  tags = {
    Name = "k8s-target-group"
  }
}

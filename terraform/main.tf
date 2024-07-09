
module "iam_policies" {
  source = "./iam-policies.tf"
}

module "iam_roles" {
  source = "./iam-roles.tf"
}



# VPC (Virtual Private Cloud)
# Creates a VPC with a specified CIDR block.
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "main-vpc"
  }
}

# Subnet
# Creates a public subnet within the VPC.
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# Internet Gateway
# Creates an internet gateway to allow internet access to the instances.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# Route Table
# Creates a route table and a route to the internet gateway.
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

# Route Table Association
# Associates the route table with the public subnet.
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.routetable.id
}

# Security Group
# Creates a security group with rules to allow necessary traffic for Kubernetes.
resource "aws_security_group" "instance" {
  vpc_id = aws_vpc.main.id

  # Allow SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Kubernetes API server access
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow etcd server client API access
  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow kubelet API access
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Flannel (UDP) access
  ingress {
    from_port   = 8285
    to_port     = 8285
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Node Exporter (for hardware metrics)
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow NodePort range
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "instance-security-group"
  }
}

# EC2 Instances for Master and Workers
# Creates EC2 instances for the Kubernetes master and worker nodes.

# Master Node
resource "aws_instance" "master" {
  ami           = "ami-052387465d846f3fc"  # Change to an appropriate AMI ID for your region
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.instance.id]
  key_name      = var.key_name
  associate_public_ip_address = true

  tags = {
    Name  = "K8s-Master"
    Group = "Kubernetes"
  }
}

# Worker Node
resource "aws_instance" "worker" {
  ami           = "ami-052387465d846f3fc"  # Change to an appropriate AMI ID for your region
  instance_type = "t3.small"
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.instance.id]
  key_name      = var.key_name
  associate_public_ip_address = true

  tags = {
    Name  = "K8s-Worker"
    Group = "Kubernetes"
  }
}

# Allocate Elastic IP for Master Node
resource "aws_eip" "master_eip" {
  instance = aws_instance.master.id
}

# Allocate Elastic IP for Worker Node
resource "aws_eip" "worker_eip" {
  instance = aws_instance.worker.id
}

# Outputs
# Provides output values for the VPC, subnet, and instances.
output "master_public_ip" {
  value = aws_eip.master_eip.public_ip
}
output "worker_public_ip" {
  value = aws_eip.worker_eip.public_ip
}

# Local-exec to update the inventory file
resource "null_resource" "update_inventory" {
  provisioner "local-exec" {
    command = <<EOT
      echo "[all]" > /root/project/devops/kubernetes/inventory
      echo "master ansible_host=${aws_eip.master_eip.public_ip} ansible_user=ec2-user" >> /root/project/devops/kubernetes/inventory
      echo "worker ansible_host=${aws_eip.worker_eip.public_ip} ansible_user=ec2-user" >> /root/project/devops/kubernetes/inventory
      echo "" >> /root/project/devops/kubernetes/inventory
      echo "[master]" >> /root/project/devops/kubernetes/inventory
      echo "master" >> /root/project/devops/kubernetes/inventory
      echo "" >> /root/project/devops/kubernetes/inventory
      echo "[workers]" >> /root/project/devops/kubernetes/inventory
      echo "worker" >> /root/project/devops/kubernetes/inventory
    EOT
  }

  triggers = {
    worker_ip = aws_eip.worker_eip.public_ip
    master_ip = aws_eip.master_eip.public_ip
  }
}
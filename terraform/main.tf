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

###########################################################################################
#                          iam-policies                                                   #
###########################################################################################

resource "aws_iam_policy" "s3_read_policy" {
  name        = "S3ReadAccess"
  description = "Policy to grant read access to S3 bucket"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::mybucket",
        "arn:aws:s3:::mybucket/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy" "ec2_full_access_policy" {
  name        = "EC2FullAccess"
  description = "Policy to grant full access to EC2 instances"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}



###########################################################################################
#                          iam-roles                                                      #
###########################################################################################


resource "aws_iam_role" "developer_role" {
  name = "developer-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "developer_s3_policy" {
  role       = aws_iam_role.developer_role.name
  policy_arn = aws_iam_policy.s3_read_policy.arn
}

resource "aws_iam_role_policy_attachment" "developer_ec2_policy" {
  role       = aws_iam_role.developer_role.name
  policy_arn = aws_iam_policy.ec2_full_access_policy.arn
}

resource "aws_iam_instance_profile" "developer_instance_profile" {
  name = "developer-instance-profile"
  role = aws_iam_role.developer_role.name
}


###########################################################################################
# EC2 Instances for Master and Workers                                                    #
# Creates EC2 instances for the Kubernetes master and worker nodes.                       #
###########################################################################################

# Master Node
resource "aws_instance" "master" {
  ami           = "ami-052387465d846f3fc"  # Change to an appropriate AMI ID for your region
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.instance.id]
  key_name      = var.key_name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user_data.sh.tmpl", {
    user_public_keys = var.user_public_keys
  })

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

  user_data = templatefile("${path.module}/user_data.sh.tmpl", {
    user_public_keys = var.user_public_keys
  })

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


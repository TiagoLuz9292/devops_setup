# VPC (Virtual Private Cloud)
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = merge({
    Name = "admin-vpc"
  }, var.environment_tags)
}

# Subnet
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = merge({
    Name = "admin-subnet"
  }, var.environment_tags)
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge({
    Name = "admin-igw"
  }, var.environment_tags)
}

# Route Table
resource "aws_route_table" "routetable" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge({
    Name = "admin-route-table"
  }, var.environment_tags)
}

# Route Table Association
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.routetable.id
}

# Security Group
resource "aws_security_group" "admin" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({
    Name = "admin-sg"
  }, var.environment_tags)
}


# IAM Role
resource "aws_iam_role" "admin_role" {
  name = "admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge({
    Name = "admin-role"
  }, var.environment_tags)
}

# IAM Policy
resource "aws_iam_policy" "admin_policy" {
  name        = "admin-policy"
  description = "Policy for admin servers to access S3 bucket and DynamoDB table"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Resource = [
          "arn:aws:s3:::terraform-state-2024-1a",
          "arn:aws:s3:::terraform-state-2024-1a/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem"
        ],
        Resource = "arn:aws:dynamodb:eu-north-1:891377403327:table/terraform-state-locks"
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeTags",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeVolumes",
          "ec2:DescribeInstanceCreditSpecifications",
          "ec2:DescribeAddresses",
          "ec2:DescribeAddressesAttribute",
          "ec2:StopInstances",
          "ec2:ModifyInstanceAttribute",
          "ec2:StartInstances"
        ],
        Resource = "*"
      }
    ]
  })

  tags = merge({
    Name = "admin-policy"
  }, var.environment_tags)
}

# IAM Role Policy Attachment
resource "aws_iam_role_policy_attachment" "admin_policy_attachment" {
  role       = aws_iam_role.admin_role.name
  policy_arn = aws_iam_policy.admin_policy.arn
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "admin_instance_profile" {
  name = "admin-instance-profile"
  role = aws_iam_role.admin_role.name

  tags = merge({
    Name = "admin-instance-profile"
  }, var.environment_tags)
}




# EC2 Instance
resource "aws_instance" "admin" {
  ami                  = var.instance_ami
  instance_type        = var.instance_type
  subnet_id            = aws_subnet.main.id
  key_name             = var.key_name
  vpc_security_group_ids = [aws_security_group.admin.id]
  iam_instance_profile = aws_iam_instance_profile.admin_instance_profile.name

  tags = merge({
    Name = "admin-instance"
  }, var.environment_tags)
}
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

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

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.routetable.id
}

resource "aws_security_group" "instance" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "instance-security-group"
  }
}

resource "aws_instance" "web1" {
  ami           = "ami-01b1be742d950fb7f"  # Change to an appropriate AMI ID for your region
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.instance.id]
  key_name      = var.key_name

  tags = {
    Name  = "WebServer1"
    Group = "Docker"
  }
}

resource "aws_instance" "web2" {
  ami           = "ami-01b1be742d950fb7f"  # Change to an appropriate AMI ID for your region
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.instance.id]
  key_name      = var.key_name

  tags = {
    Name  = "WebServer2"
    Group = "Docker"
  }
}


resource "aws_s3_bucket" "app_bucket" {
  bucket = "my-app-bucket-${lower(random_string.bucket_suffix.result)}"
  force_destroy = true  # Optional: to delete non-empty buckets

  tags = {
    Name        = "My app bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_ownership_controls" "app_bucket_ownership" {
  bucket = aws_s3_bucket.app_bucket.bucket

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "random_string" "bucket_suffix" {
  length  = 6
  special = false
}
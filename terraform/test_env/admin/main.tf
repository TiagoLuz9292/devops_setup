# Provider configuration for AWS
provider "aws" {
  region = var.region
}

# Fetching remote state data from the networking configuration
data "terraform_remote_state" "networking" {
  backend = "local"
  config = {
    path = "../networking/terraform.tfstate"
  }
}

# Admin EC2 Instance
# This resource creates an EC2 instance for administrative purposes
resource "aws_instance" "admin" {
  ami                         = "ami-052387465d846f3fc" # Change to an appropriate AMI ID for your region
  instance_type               = var.instance_type
  subnet_id                   = data.terraform_remote_state.networking.outputs.admin_subnet_id
  vpc_security_group_ids      = [data.terraform_remote_state.networking.outputs.instance_security_group_id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  # User data script to prepare the environment on instance launch
  user_data = file("/home/ec2-user/devops_setup/prepare_env.sh")

  tags = {
    Name  = "test-Admin-Server"
    Group = "Admin"
  }
}

# Elastic IP for Admin Instance
# This resource creates an Elastic IP and associates it with the admin EC2 instance
resource "aws_eip" "admin_eip" {
  instance = aws_instance.admin.id
}

# Output for Admin Public IP
output "admin_public_ip" {
  value = aws_eip.admin_eip.public_ip
}

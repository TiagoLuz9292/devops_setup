provider "aws" {
  region = var.region
}

data "terraform_remote_state" "networking" {
  backend = "s3"

  config = {
    bucket         = "terraform-state-2024-1a"
    key            = "networking/vpc_main/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-state-locks"
  }
}

data "terraform_remote_state" "iam" {
  backend = "s3"

  config = {
    bucket         = "terraform-state-2024-1a"
    key            = "iam/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-state-locks"
  }
}

resource "aws_instance" "admin" {
  ami           = "ami-052387465d846f3fc"  # Change to an appropriate AMI ID for your region
  instance_type = var.instance_type
  subnet_id     = data.terraform_remote_state.networking.outputs.admin_subnet_id
  vpc_security_group_ids = [data.terraform_remote_state.networking.outputs.instance_security_group_id]
  key_name      = var.key_name
  associate_public_ip_address = true
  iam_instance_profile = data.terraform_remote_state.iam.outputs.admin_instance_profile_name

  user_data = file("/home/ec2-user/devops_setup/admin_server/prepare_env.sh")

  tags = {
    Name  = "Admin-Server"
    Group = "Admin"
  }
}

resource "aws_eip" "admin_eip" {
  instance = aws_instance.admin.id
}

output "admin_public_ip" {
  value = aws_eip.admin_eip.public_ip
}

provider "aws" {
  region = var.region
}

data "terraform_remote_state" "networking" {
  backend = "local"

  config = {
    path = "../networking/terraform.tfstate"
  }
}

resource "aws_instance" "admin" {
  ami           = "ami-052387465d846f3fc"  # Change to an appropriate AMI ID for your region
  instance_type = var.instance_type
  subnet_id     = data.terraform_remote_state.networking.outputs.admin_subnet_id
  vpc_security_group_ids = [data.terraform_remote_state.networking.outputs.instance_security_group_id]
  key_name      = var.key_name
  associate_public_ip_address = true

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

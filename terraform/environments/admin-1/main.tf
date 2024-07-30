provider "aws" {
  region = var.region
}

data "local_file" "provision_script" {
  filename = var.provision_script_path
}

module "admin_vpc" {
  source               = "../../modules/networking"
  vpc_cidr             = var.vpc_cidr
  subnet_cidr1         = var.subnet_cidr1
  subnet_cidr2         = var.subnet_cidr2
  availability_zone1   = var.availability_zone1
  availability_zone2   = var.availability_zone2
  vpc_name             = var.vpc_name
  subnet_name1         = var.subnet_name1
  subnet_name2         = var.subnet_name2
  igw_name             = var.igw_name
  route_table_name     = var.route_table_name
  environment_tags     = var.environment_tags
}

data "terraform_remote_state" "iam" {
  backend = "s3"
  config = {
    bucket = "terraform-state-2024-1a"
    key    = "iam/terraform.tfstate"
    region = "eu-north-1"
  }
}

module "admin_instance" {
  source                  = "../../modules/ec2"
  ami                     = var.admin_ami
  instance_type           = var.admin_instance_type
  subnet_id               = module.admin_vpc.subnet1_id
  security_group_id       = module.admin_vpc.instance_security_group_id
  key_name                = var.key_name
  associate_public_ip_address = true
  iam_instance_profile    = data.terraform_remote_state.iam.outputs.admin_instance_profile_name
  provision_command       = data.local_file.provision_script.content
  tags = {
    Name  = var.admin_instance_name
    Group = "Admin"
  }
}

provider "aws" {
  region = var.region
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

data "terraform_remote_state" "admin" {
  backend = "s3"

  config = {
    bucket         = "terraform-state-2024-1a"
    key            = "admin-main/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-state-locks"
  }
}

module "networking" {
  source = "../../../modules/networking"

  vpc_cidr               = "10.0.0.0/16"
  subnet_cidr1           = "10.0.1.0/24"
  subnet_cidr2           = "10.0.2.0/24"
  availability_zone1     = "eu-north-1a"
  availability_zone2     = "eu-north-1b"
  vpc_name               = "dev-vpc"
  subnet_name1           = "dev-public-subnet-1"
  subnet_name2           = "dev-public-subnet-2"
  igw_name               = "dev-igw"
  route_table_name       = "dev-route-table"
  elb_security_group_name = "dev-elb-sg"
  instance_security_group_name = "dev-instance-sg"
  k8s_target_group_name  = "dev-k8s-tg"
  environment_tags       = {
    Environment = "dev"
  }
}


resource "aws_vpc_peering_connection" "peer" {
  vpc_id        = module.networking.vpc_id
  peer_vpc_id   = data.terraform_remote_state.admin.outputs.vpc_id
  peer_region   = "eu-north-1"
  auto_accept   = false

  tags = merge({
    Name = "dev-admin-peer"
  }, var.environment_tags)
}


resource "aws_vpc_peering_connection_accepter" "peer_accept" {
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  auto_accept               = true

  tags = merge({
    Name = "dev-admin-peer"
  }, var.environment_tags)
}

# Add routes to allow traffic between VPCs
resource "aws_route" "dev_to_admin" {
  route_table_id         = module.networking.route_table_id
  destination_cidr_block = data.terraform_remote_state.admin.outputs.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

resource "aws_route" "admin_to_dev" {
  route_table_id         = data.terraform_remote_state.admin.outputs.route_table_id
  destination_cidr_block = module.networking.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
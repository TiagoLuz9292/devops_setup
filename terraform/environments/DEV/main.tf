# environments/test/main.tf

provider "aws" {
  region = var.region
}

module "networking" {
  source = "../../modules/networking"

  vpc_cidr                  = var.vpc_cidr
  subnet_cidr1              = var.subnet_cidr1
  subnet_cidr2              = var.subnet_cidr2
  availability_zone1        = var.availability_zone1
  availability_zone2        = var.availability_zone2
  vpc_name                  = "test-main-vpc"
  subnet_name1              = "test-public-subnet-1"
  subnet_name2              = "test-public-subnet-2"
  igw_name                  = "test-main-igw"
  route_table_name          = "test-main-route-table"
  elb_security_group_name   = "test-elb-security-group"
  instance_security_group_name = "test-instance-security-group"
  k8s_target_group_name     = "test-k8s-target-group"
}

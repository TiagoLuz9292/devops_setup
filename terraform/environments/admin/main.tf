provider "aws" {
  region = var.region
}

module "admin" {
  source = "../../modules/admin"

  vpc_cidr           = var.vpc_cidr
  subnet_cidr        = var.subnet_cidr
  availability_zone  = var.availability_zone
  instance_type      = var.instance_type
  instance_ami       = var.instance_ami
  key_name           = var.key_name
  environment_tags   = var.environment_tags
}

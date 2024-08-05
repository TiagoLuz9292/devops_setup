provider "aws" {
  region = var.region
}



module "dev_vpc" {
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
  environment          = var.environment
  vpc_id               = module.dev_vpc.vpc_id
  environment_tags      = var.environment_tags
  subnet_ids            = [module.dev_vpc.subnet1_id, module.dev_vpc.subnet2_id]
}

data "terraform_remote_state" "iam" {
  backend = "s3"
  config = {
    bucket = "terraform-state-2024-1a"
    key    = "iam/terraform.tfstate"
    region = "eu-north-1"
  }
}

data "terraform_remote_state" "admin" {
  backend = "s3"
  config = {
    bucket = "terraform-state-2024-1a"
    key    = "admin-1/terraform.tfstate"
    region = "eu-north-1"
  }
}

module "vpc_peering" {
  source                = "../../modules/vpc_peering"
  vpc_id                = module.dev_vpc.vpc_id
  peer_vpc_id           = data.terraform_remote_state.admin.outputs.admin_vpc_id
  peer_vpc_cidr         = data.terraform_remote_state.admin.outputs.admin_vpc_cidr
  vpc_cidr              = var.vpc_cidr
  route_table_id        = module.dev_vpc.route_table_id
  admin_route_table_id  = data.terraform_remote_state.admin.outputs.route_table_id
  peer_name             = "dev-admin-peer"
  environment_tags      = var.environment_tags
}

module "k8s_cluster" {
  depends_on            = [module.vpc_peering]

  source                = "../../modules/k8s_cluster"
  master_ami            = var.master_ami
  instance_type         = var.instance_type
  subnet_id             = module.dev_vpc.subnet1_id
  security_group_id     = module.dev_vpc.instance_security_group_id
  key_name              = var.key_name
  master_instance_profile = data.terraform_remote_state.iam.outputs.master_instance_profile_name
  master_instance_name  = var.master_instance_name
  vpc_id                = module.dev_vpc.vpc_id
  worker_ami            = var.worker_ami
  worker_instance_profile = data.terraform_remote_state.iam.outputs.worker_instance_profile_name
  worker_instance_name  = var.worker_instance_name
  worker_user_data      = var.worker_user_data
  desired_capacity      = var.desired_capacity
  max_size              = var.max_size
  min_size              = var.min_size
  subnet_ids            = [module.dev_vpc.subnet1_id, module.dev_vpc.subnet2_id]
  environment           = var.environment
  target_group_arns     = [module.elb.target_group_arn]
}



module "cloudwatch_alarms" {
  source                = "../../modules/cloudwatch_alarms"
  asg_name              = module.k8s_cluster.asg_name
  scale_out_policy_arn  = module.k8s_cluster.scale_out_policy_arn
  scale_in_policy_arn   = module.k8s_cluster.scale_in_policy_arn
  high_cpu_threshold    = var.high_cpu_threshold
  low_cpu_threshold     = var.low_cpu_threshold
  evaluation_periods    = var.evaluation_periods
  period                = var.period
}



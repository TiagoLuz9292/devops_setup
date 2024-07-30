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

data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "terraform-state-2024-1a"
    key    = "DEV/networking/terraform.tfstate"
    region = "eu-north-1"
  }
}


module "k8s_cluster" {
  source = "../../../modules/k8s_cluster"

  instance_type          = "t3.medium"
  key_name               = "devOps_training"
  private_key_path       = "/home/ec2-user/.ssh/my-key-pair"
  region                 = "eu-north-1"
  desired_capacity       = 1
  max_size               = 4
  min_size               = 1
  master_ami             = "ami-052387465d846f3fc"
  worker_ami             = "ami-052387465d846f3fc"
  master_instance_name   = "K8s-Master-DEV"
  worker_instance_name   = "K8s-Worker-DEV"
  worker_user_data       = file("${path.module}/worker_user_data.sh")
  environment            = "DEV"
  update_inventory_command = file("${path.module}/update_inventory.sh")
  subnet_id              = data.terraform_remote_state.networking.outputs.public_subnet_id1
  subnet_ids           = [
    data.terraform_remote_state.networking.outputs.public_subnet_id1,
    data.terraform_remote_state.networking.outputs.public_subnet_id2
  ]
  security_group_id      = data.terraform_remote_state.networking.outputs.instance_security_group_id
  master_instance_profile = data.terraform_remote_state.iam.outputs.master_instance_profile_name
  worker_instance_profile = data.terraform_remote_state.iam.outputs.worker_instance_profile_name
  lb_target_group_arn    = data.terraform_remote_state.networking.outputs.lb_target_group_arn
}

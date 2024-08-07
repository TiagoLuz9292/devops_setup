region                 = "eu-north-1"
vpc_cidr               = "10.0.0.0/16"
subnet_cidr1           = "10.0.1.0/24"
subnet_cidr2           = "10.0.2.0/24"
availability_zone1     = "eu-north-1a"
availability_zone2     = "eu-north-1b"
vpc_name               = "admin-1-vpc"
subnet_name1           = "admin-1-subnet-1"
subnet_name2           = "admin-1-subnet-2"
igw_name               = "admin-1-igw"
route_table_name       = "admin-1-route-table"
environment_tags       = { Environment = "admin-1" }

admin_ami              = "ami-052387465d846f3fc"
admin_instance_type    = "t3.medium"
key_name               = "devOps_training"
admin_instance_name    = "admin-1"
provision_script_path  = "/home/ec2-user/devops_setup/terraform/environments/admin-1/prepare_env.sh"

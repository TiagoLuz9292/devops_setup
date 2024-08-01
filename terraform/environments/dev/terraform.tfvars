region                 = "eu-north-1"
vpc_cidr               = "10.1.0.0/16"
subnet_cidr1           = "10.1.1.0/24"
subnet_cidr2           = "10.1.2.0/24"
availability_zone1     = "eu-north-1a"
availability_zone2     = "eu-north-1b"
vpc_name               = "dev-vpc"
subnet_name1           = "dev-subnet-1"
subnet_name2           = "dev-subnet-2"
igw_name               = "dev-igw"
route_table_name       = "dev-route-table"
environment_tags       = { Environment = "dev" }
master_ami             = "ami-052387465d846f3fc"
instance_type          = "t3.medium"
key_name               = "devOps_training"
master_instance_name   = "k8s-master-dev"
worker_ami             = "ami-052387465d846f3fc"
worker_instance_name   = "k8s-worker-dev"
worker_user_data       = "your-user-data"
desired_capacity       = 1
max_size               = 2
min_size               = 1

environment            = "dev"

high_cpu_threshold     = 50
low_cpu_threshold      = 30
evaluation_periods     = 1
period                 = 120
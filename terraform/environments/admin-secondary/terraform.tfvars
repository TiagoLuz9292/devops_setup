region             = "eu-north-1"
vpc_cidr           = "10.6.0.0/16"
subnet_cidr        = "10.6.1.0/24"
availability_zone  = "eu-north-1a"
instance_ami       = "ami-052387465d846f3fc"
key_name           = "devOps_training"
environment_tags   = {
  Environment = "admin-sec"
}

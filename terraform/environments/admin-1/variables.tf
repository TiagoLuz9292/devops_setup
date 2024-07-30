variable "region" {}
variable "vpc_cidr" {}
variable "subnet_cidr1" {}
variable "subnet_cidr2" {}
variable "availability_zone1" {}
variable "availability_zone2" {}
variable "vpc_name" {}
variable "subnet_name1" {}
variable "subnet_name2" {}
variable "igw_name" {}
variable "route_table_name" {}
variable "environment_tags" {}
variable "admin_ami" {}
variable "admin_instance_type" {}
variable "key_name" {}
variable "admin_instance_name" {}
variable "provision_script_path" {
  description = "Path to the provision script"
  type        = string
}
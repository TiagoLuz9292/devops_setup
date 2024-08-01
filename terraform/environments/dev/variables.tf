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
variable "master_ami" {}
variable "instance_type" {}
variable "key_name" {}
variable "master_instance_name" {}
variable "worker_ami" {}
variable "worker_instance_name" {}
variable "worker_user_data" {}
variable "desired_capacity" {}
variable "max_size" {}
variable "min_size" {}

variable "environment" {}

variable "high_cpu_threshold" {
  description = "High CPU utilization threshold"
  type        = number
}

variable "low_cpu_threshold" {
  description = "Low CPU utilization threshold"
  type        = number
}

variable "evaluation_periods" {
  description = "Evaluation periods for the alarms"
  type        = number
}

variable "period" {
  description = "Period for the alarms"
  type        = number
}

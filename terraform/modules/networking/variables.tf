# modules/networking/variables.tf

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "subnet_cidr1" {
  description = "CIDR block for the first public subnet"
  type        = string
}

variable "subnet_cidr2" {
  description = "CIDR block for the second public subnet"
  type        = string
}

variable "admin_subnet_cidr" {
  description = "CIDR block for the admin subnet"
  type        = string
}

variable "availability_zone1" {
  description = "Availability zone for the first public subnet"
  type        = string
}

variable "availability_zone2" {
  description = "Availability zone for the second public subnet"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "subnet_name1" {
  description = "Name of the first public subnet"
  type        = string
}

variable "subnet_name2" {
  description = "Name of the second public subnet"
  type        = string
}

variable "admin_subnet_name" {
  description = "Name of the admin subnet"
  type        = string
}

variable "igw_name" {
  description = "Name of the Internet Gateway"
  type        = string
}

variable "route_table_name" {
  description = "Name of the Route Table"
  type        = string
}

variable "elb_security_group_name" {
  description = "Name of the ELB security group"
  type        = string
}

variable "instance_security_group_name" {
  description = "Name of the instance security group"
  type        = string
}

variable "k8s_target_group_name" {
  description = "Name of the Kubernetes target group"
  type        = string
}

variable "environment_tags" {
  description = "Environment-specific tags"
  type        = map(string)
}
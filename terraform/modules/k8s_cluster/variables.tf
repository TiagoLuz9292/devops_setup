variable "instance_type" {
  description = "Type of EC2 instance"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "private_key_path" {
  description = "Path of private key"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "desired_capacity" {
  description = "Desired capacity for ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum size for ASG"
  type        = number
  default     = 4
}

variable "min_size" {
  description = "Minimum size for ASG"
  type        = number
  default     = 1
}

variable "master_ami" {
  description = "AMI ID for the master instance"
  type        = string
}

variable "worker_ami" {
  description = "AMI ID for the worker instances"
  type        = string
}

variable "master_instance_name" {
  description = "Name tag for the master instance"
  type        = string
}

variable "worker_instance_name" {
  description = "Name tag for the worker instances"
  type        = string
}

variable "worker_user_data" {
  description = "User data script for worker instances"
  type        = string
}


variable "update_inventory_command" {
  description = "Command to update the inventory file"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet for the master instance"
  type        = string
}

variable "subnet_ids" {
  description = "IDs of the subnets for the worker instances"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID of the security group for the instances"
  type        = string
}

variable "master_instance_profile" {
  description = "IAM instance profile for the master instance"
  type        = string
}

variable "worker_instance_profile" {
  description = "IAM instance profile for the worker instances"
  type        = string
}

variable "lb_target_group_arn" {
  description = "ARN of the load balancer target group"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}
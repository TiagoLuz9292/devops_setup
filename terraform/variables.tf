'# Variable definitions for instance type, VPC and subnet CIDR blocks, region, and SSH key pair name.

variable "instance_type" {
  description = "Type of EC2 instance"
  type        = string
  default     = "t3.medium"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}



variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "devOps_training"  # Replace with your actual key pair name
}

variable "private_key_path" {
  description = "Path of private key"
  type        = string
  default     = "/root/.ssh/my-key-pair"  # Replace with your actual key pair name
}


variable "user_names" {
  description = "List of user names"
  type        = list(string)
  default     = []
}

variable "user_public_keys" {
  description = "Map of user names to their public keys"
  type        = map(string)
  default     = {}
}'
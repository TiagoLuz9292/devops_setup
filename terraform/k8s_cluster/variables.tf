variable "instance_type" {
  description = "Type of EC2 instance"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "devOps_training"
}

variable "private_key_path" {
  description = "Path of private key"
  type        = string
  default     = "/root/.ssh/my-key-pair"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "desired_capacity" {
  description = "Desired capacity for ASG"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum size for ASG"
  type        = number
  default     = 4
}

variable "min_size" {
  description = "Minimum size for ASG"
  type        = number
  default     = 2
}

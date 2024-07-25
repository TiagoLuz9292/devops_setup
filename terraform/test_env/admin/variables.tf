variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "instance_type" {
  description = "Type of EC2 instance"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "devOps_training"  # Replace with your actual key pair name
}

variable "user_public_keys" {
  description = "Map of user names to their public keys"
  type        = map(string)
  default     = {}
}

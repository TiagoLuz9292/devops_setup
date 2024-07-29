variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.1.0.0/16"
}


variable "admin_subnet_cidr" {
  description = "CIDR block for the admin subnet"
  type        = string
  default     = "10.1.1.0/24"
}

variable "availability_zone1" {
  description = "Availability zone for the first public subnet"
  type        = string
  default     = "eu-north-1a"
}

variable "availability_zone2" {
  description = "Availability zone for the second public subnet"
  type        = string
  default     = "eu-north-1b"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

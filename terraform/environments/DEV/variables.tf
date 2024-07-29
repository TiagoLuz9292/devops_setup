# environments/test/variables.tf

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr1" {
  description = "CIDR block for the first public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_cidr2" {
  description = "CIDR block for the second public subnet"
  type        = string
  default     = "10.0.2.0/24"
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


variable "environment_tags" {
  description = "Environment-specific tags"
  type        = map(string)
  default     = {
    Environment = "DEV"
    Project     = "AWS Infrastructure"
  }
}
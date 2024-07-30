# environments/test/variables.tf

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}


variable "environment_tags" {
  description = "Environment-specific tags"
  type        = map(string)
  default     = {
    Environment = "DEV"
    Project     = "AWS Infrastructure"
  }
}
variable "region" {
  description = "The AWS region to create resources in"
  default     = "eu-north-1"
}

variable "bucket_name" {
  description = "The name of the S3 bucket for storing Terraform state"
  default     = "terraform_state"
}

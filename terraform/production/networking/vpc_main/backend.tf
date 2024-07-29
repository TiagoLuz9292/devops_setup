terraform {
  backend "s3" {
    bucket         = "terraform-state-2024-1a"
    key            = "networking/vpc_main/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
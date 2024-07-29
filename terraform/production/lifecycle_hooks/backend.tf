terraform {
  backend "s3" {
    bucket         = "terraform_state"
    key            = "networking/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
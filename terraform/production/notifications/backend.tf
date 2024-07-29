terraform {
  backend "s3" {
    bucket         = "terraform_state"
    key            = "notifications/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
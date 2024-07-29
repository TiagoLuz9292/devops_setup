# environments/test/backend.tf

terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "test/terraform.tfstate"
    region = "eu-north-1"
  }
}

terraform {
  backend "s3" {
    bucket = "terraform-state-2024-1a"
    key    = "admin-main/terraform.tfstate"
    region = "eu-north-1"
  }
}

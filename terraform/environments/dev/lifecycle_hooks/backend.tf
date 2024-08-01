# environments/test/backend.tf

terraform {
  backend "s3" {
    bucket = "terraform-state-2024-1a"
    key    = "dev/lifecycle_hooks/terraform.tfstate"
    region = "eu-north-1"
  }
}

# environments/test/backend.tf

terraform {
  backend "s3" {
    bucket = "terraform-state-2024-1a"
    key    = "DEV/k8s_cluster/terraform.tfstate"
    region = "eu-north-1"
  }
}

terraform {
  backend "s3" {
    bucket         = "terraform-state-2024-1a"
    key            = "k8s_cluster/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
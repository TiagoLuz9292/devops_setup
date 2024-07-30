terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
      version = "2.1.0" # specify the version you want
    }
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
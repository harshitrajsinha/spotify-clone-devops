terraform {
  required_version = "~> 1.15.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.51.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}
terraform {
  required_version = ">= 1.14.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  backend "s3" {
    bucket       = "tfstate-buckets3-2026"
    key          = "terraform/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}
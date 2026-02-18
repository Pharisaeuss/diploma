terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  backend "s3" {
    bucket         = "tfstate-bucket-backup2026"
    key            = "terraform/terraform.tfstate"

    use_lockfile = true
  }
}
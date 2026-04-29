locals {
  env          = get_env("TG_ENV", "dev")
  state_bucket = get_env("TG_STATE_BUCKET", "tfstate-buckets3-2026")
  region       = get_env("AWS_REGION", "eu-central-1")
}

# Generate provider configuration for AWS
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.region}"
  default_tags {
    tags = {
      ManagedBy   = "Terragrunt"
      Environment = "${local.env}"  
      Project     = "DevOps-Diploma"
    }
  }
}
EOF
}

# State backend configuration 
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket       = local.state_bucket
    key          = "${path_relative_to_include()}/terraform.tfstate"
    region       = local.region
    encrypt      = true
    use_lockfile = true
  }
}

inputs = {
  env    = local.env
  region = local.region
}
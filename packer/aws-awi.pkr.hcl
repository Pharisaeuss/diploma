packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

variable "aws_region" {
  type    = string
  default = env("AWS_REGION")
}

variable "project_env" {
  type        = string
  default     = env("PROJECT_ENV")
  description = "Deployment environment: dev | stage | prod"
}

variable "instance_type" {
  type    = string
  default = "c7i-flex.large" 
}

source "amazon-ebs" "fastapi_app" {
  ami_name      = "fastapi-crud-${var.project_env}-v${formatdate("YYYYMMDD-hhmm", timestamp())}"
  instance_type = var.instance_type
  region        = var.aws_region != "" ? var.aws_region : "eu-central-1"

  ami_description = "FastAPI CRUD golden image env=${var.project_env}"
  tags = {
    Name        = "fastapi-crud-${var.project_env}"
    Environment = var.project_env
    BuildTime   = formatdate("YYYY-MM-DD hh:mm", timestamp())
    ManagedBy   = "packer"
  }

  source_ami_filter {
    filters = {
      name                = "al2023-ami-2023*-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  ssh_username = "ec2-user"
  shutdown_behavior = "terminate"
}

build {
  sources = ["source.amazon-ebs.fastapi_app"]

  # Start Ansible playbook after the image is created
  provisioner "ansible" {
    playbook_file = "../ansible/playbook.yml"
    user          = "ec2-user"
    use_proxy     = false
    ansible_env_vars = [
      "ANSIBLE_HOST_KEY_CHECKING=False",
      "PROJECT_ENV=${var.project_env}",
       "AWS_DEFAULT_REGION=${var.aws_region != "" ? var.aws_region : "eu-central-1"}",
    ]
    # start_services=false → Ansible enables units but does NOT start them
    extra_arguments = [
      "--extra-vars", "start_services=false",
    ]
  }
}
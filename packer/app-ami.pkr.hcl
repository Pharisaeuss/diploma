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
  type    = string
  default = env("PROJECT_ENV")
}

variable "instance_type" {
  type    = string
  default = "t3.small"  
}

# Source: latest Base AMI 
source "amazon-ebs" "app" {
  ami_name        = "fastapi-crud-${var.project_env}-v${formatdate("YYYYMMDD-hhmm", timestamp())}"
  ami_description = "App layer: code + config baked on top of Base AMI. env=${var.project_env}"
  instance_type   = var.instance_type
  region          = var.aws_region != "" ? var.aws_region : "eu-central-1"

  # Start from the Base AMI — all packages already installed
  source_ami_filter {
    filters = {
      name                = "fastapi-crud-BASE-*"
    }
    most_recent = true
    owners      = ["self"]
  }

  ssh_username      = "ec2-user"
  shutdown_behavior = "terminate"

  tags = {
    Name        = "fastapi-crud-${var.project_env}"
    Layer       = "app"
    Environment = var.project_env
    BaseAmi     = "{{ .SourceAMI }}"
    BaseAmiName = "{{ .SourceAMIName }}"
    ManagedBy   = "packer"
    BuildTime   = formatdate("YYYY-MM-DD hh:mm", timestamp())
  }
}

build {
  sources = ["source.amazon-ebs.app"]

  provisioner "ansible" {
    playbook_file = "../ansible/deploy_app/playbook.yml"
    user          = "ec2-user"
    use_proxy     = false

    ansible_env_vars = [
      "ANSIBLE_HOST_KEY_CHECKING=False",
      "PROJECT_ENV=${var.project_env}",
      "AWS_DEFAULT_REGION=${var.aws_region != "" ? var.aws_region : "eu-central-1"}",
    ]

    # Do not start services during bake — SSM/RDS not reachable yet
    extra_arguments = ["--extra-vars", "start_services=false"]
  }
}

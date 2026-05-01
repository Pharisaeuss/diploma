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

variable "instance_type" {
  type    = string
  default = "c7i-flex.large"
}

# ── Source: latest Amazon Linux 2023 ──────────────────────────────────────────
source "amazon-ebs" "base" {
  ami_name      = "fastapi-crud-BASE-${formatdate("YYYYMMDD-hhmm", timestamp())}"
  ami_description = "Base layer: OS deps, Python, Nginx, awscli, empty venv. NO app code."
  instance_type = var.instance_type
  region        = var.aws_region != "" ? var.aws_region : "eu-central-1"

  source_ami_filter {
    filters = {
      name                = "al2023-ami-2023*-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }

  ssh_username      = "ec2-user"
  shutdown_behavior = "terminate"

  tags = {
    Name      = "fastapi-crud-BASE"
    Layer     = "base"
    ManagedBy = "packer"
    BuildTime = formatdate("YYYY-MM-DD hh:mm", timestamp())
  }
}

build {
  sources = ["source.amazon-ebs.base"]

  provisioner "ansible" {
    playbook_file = "../ansible/base/playbook.yml"
    user          = "ec2-user"
    use_proxy     = false

    ansible_env_vars = [
      "ANSIBLE_HOST_KEY_CHECKING=False",
    ]

    # Base bake never starts services — nothing to start yet
    extra_arguments = ["--extra-vars", "start_services=false"]
  }
}

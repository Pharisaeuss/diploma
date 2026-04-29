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

source "amazon-ebs" "streamlit_app" {
  ami_name      = "streamlit-app-v${formatdate("YYYYMMDD-hhmm", timestamp())}"
  instance_type = "c7i-flex.large"
  region        = get_env("AWS_REGION", "eu-central-1")

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
}

build {
  sources = ["source.amazon-ebs.streamlit_app"]

  # Start Ansible playbook after the image is created
  provisioner "ansible" {
    playbook_file = "../ansible/playbook.yml"
    user          = "ec2-user"
    use_proxy     = false
    ansible_env_vars = [
      "ANSIBLE_HOST_KEY_CHECKING=False"
    ]
  }
}
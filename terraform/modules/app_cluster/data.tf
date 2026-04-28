data "aws_ami" "latest_golden_image" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["streamlit-app-v*"]
  }
}

# Default Amazon Linux 2023 AMI as a fallback
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

locals {
  ami_id = try(data.aws_ami.latest_golden_image.id, data.aws_ami.amazon_linux.id)
}
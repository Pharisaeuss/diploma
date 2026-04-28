data "aws_ami" "app_ami" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["streamlit-app-v*"]
  }
}
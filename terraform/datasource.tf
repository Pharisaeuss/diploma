# Get the Default VPC
data "aws_vpc" "default" {
  default = true
}

# Get the latest Amazon Linux 2023 AMI 
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]


  filter {
    name   = "name"
    values = [var.image]
  }
}

# Get all available AZs in your current region
data "aws_availability_zones" "available" {
  state = "available"
}
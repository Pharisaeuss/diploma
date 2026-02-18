# Create a specific Subnet in the Default VPC
resource "aws_subnet" "custom_asg_subnet" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.200.0/24" 
  availability_zone       = var.zone     
  map_public_ip_on_launch = true            

  tags = {
    Name = "EC2-ASG-Subnet-${var.env}"
  }
}

# Security Group for the ASG
resource "aws_security_group" "asg_sg" {
  name        = "asg-security-group-${var.env}"
  description = "Allow HTTP and SSH"  # later change for only allowing load balancer traffic
  vpc_id      = data.aws_vpc.default.id

  # Inbound Rules
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound Rules (Allow all traffic out)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
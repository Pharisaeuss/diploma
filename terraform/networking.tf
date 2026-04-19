# =============== SUBNETS ===============
#  ASG Subnet (Private)
resource "aws_subnet" "custom_asg_subnet" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.200.0/24"
  availability_zone       = var.zone
  map_public_ip_on_launch = false

  tags = {
    Name = "EC2-ASG-Subnet-${var.env}"
  }
}

# Subnet for ALB Zone 1
resource "aws_subnet" "custom_alb_subnet_1" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.201.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "Subnet-ALB-Zone-2-${var.env}"
  }
}

# Subnet for ALB Zone 2
resource "aws_subnet" "custom_alb_subnet_2" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.202.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "Subnet-ALB-Zone-2-${var.env}"
  }
}

# Subnet for DB Tier (Private) - Zone A
resource "aws_subnet" "db_private_1" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.203.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = { Name = "Subnet-DB-Tier-1-${var.env}" }
}

# Subnet for DB Tier (Private) - Zone B
resource "aws_subnet" "db_private_2" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.204.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = { Name = "Subnet-DB-Tier-2-${var.env}" }
}

# Public Subnet for NAT Gateway
resource "aws_subnet" "public_subnet_nat" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.250.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "Subnet-NAT-Gateway-${var.env}" }
}

# =============== SECURITY GROUPS ===============
# Security Group for the ASG
resource "aws_security_group" "asg_sg" {
  name        = "asg-security-group-${var.env}"
  description = "Allow HTTP and SSH"
  vpc_id      = data.aws_vpc.default.id

  # Inbound Rules
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.eice_sg]
  }

  # Outbound Rules (Allow all traffic out)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb_sg" {
  name   = "alb-sg-${var.env}"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open to world
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Dedicated Security Group for the Endpoint
resource "aws_security_group" "eice_sg" {
  name        = "eice-security-group"
  description = "Security group for EC2 Instance Connect Endpoint"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    security_groups = [aws_security_group.asg_sg.id]
  }
}

# Security Group для PostgreSQL
resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group-${var.env}"
  description = "Allow PostgreSQL traffic from ASG instances only"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.asg_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
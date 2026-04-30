#  ASG Subnet (Private) - Zone 1
resource "aws_subnet" "asg_subnet_1" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.200.0/24"
  availability_zone       = var.zone
  map_public_ip_on_launch = false

  tags = {
    Name = "EC2-ASG-Subnet-${var.env}"
  }
}

# ASG Subnet (Private) - Zone 2
resource "aws_subnet" "asg_subnet_2" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.205.0/24" 
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = { Name = "EC2-ASG-Subnet-2-${var.env}" }
}

# Subnet for ALB Zone 1
resource "aws_subnet" "alb_subnet_1" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.201.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "Subnet-ALB-Zone-1-${var.env}"
  }
}

# Subnet for ALB Zone 2
resource "aws_subnet" "alb_subnet_2" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.202.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "Subnet-ALB-Zone-2-${var.env}"
  }
}

# Subnet for DB (Private) - Zone A
resource "aws_subnet" "db_private_1" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.203.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = { Name = "Subnet-DB-Zone-1-${var.env}" }
}

# Subnet for DB (Private) - Zone B
resource "aws_subnet" "db_private_2" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.204.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = { Name = "Subnet-DB-Zone-2-${var.env}" }
}

# Public Subnet for NAT Gateway
resource "aws_subnet" "public_subnet_nat" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.250.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "Subnet-NAT-Gateway-${var.env}" }
}
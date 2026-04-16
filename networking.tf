# Create a specific Subnet in the Default VPC
resource "aws_subnet" "custom_asg_subnet" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.200.0/24"
  availability_zone       = var.zone
  map_public_ip_on_launch = false

  tags = {
    Name = "EC2-ASG-Subnet-${var.env}"
  }
}

# Subnet for ALB
resource "aws_subnet" "custom_alb_subnet_1" {
  vpc_id = data.aws_vpc.default.id
  # Use a different CIDR that doesn't conflict
  cidr_block = "172.31.201.0/24"
  # Use the second available AZ (index 1)
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "Subnet-ALB-Zone-2-${var.env}"
  }
}

resource "aws_subnet" "custom_alb_subnet_2" {
  vpc_id = data.aws_vpc.default.id
  # Use a different CIDR that doesn't conflict
  cidr_block = "172.31.202.0/24"
  # Use the second available AZ (index 1)
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "Subnet-ALB-Zone-2-${var.env}"
  }
}

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




# 1. Dedicated Security Group for the Endpoint
resource "aws_security_group" "eice_sg" {
  name        = "eice-security-group"
  description = "Security group for EC2 Instance Connect Endpoint"
  vpc_id      = data.aws_vpc.default.id # Replace with your VPC ID reference

  # The endpoint only needs outbound access to your EC2 instances on port 22
  egress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    # Point this to your existing EC2 instance's security group
    security_groups = [aws_security_group.asg_sg.id]
  }
}

# 1-ша виділена підмережа для БД (Zone A)
resource "aws_subnet" "db_private_1" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.203.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  
  tags = { Name = "Subnet-DB-Tier-1-${var.env}" }
}

# 2-га виділена підмережа для БД (Zone B)
resource "aws_subnet" "db_private_2" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.204.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  
  tags = { Name = "Subnet-DB-Tier-2-${var.env}" }
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



# Окрема Security Group для ендпоінтів
resource "aws_security_group" "ssm_endpoints_sg" {
  name        = "ssm-endpoints-sg-${var.env}"
  description = "Security group for SSM Interface Endpoints"
  vpc_id      = data.aws_vpc.default.id

  # Дозволяємо вхідний HTTPS (443) ТІЛЬКИ від наших серверів 
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.asg_sg.id]
  }

  # Вихідний трафік для ендпоінтів
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
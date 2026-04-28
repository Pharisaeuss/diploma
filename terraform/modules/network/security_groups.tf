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
    security_groups = [aws_security_group.eice_sg.id]
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
}

# rules for EICE to allow outbound SSH to ASG instances
resource "aws_security_group_rule" "eice_egress_to_asg" {
  type                     = "egress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eice_sg.id
  source_security_group_id = aws_security_group.asg_sg.id
}

# Security Group for PostgreSQL
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
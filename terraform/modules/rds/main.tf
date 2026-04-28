# Create Group of subnets for RDS
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "main-db-subnet-group-${var.env}"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name = "PostgreSQL Subnet Group ${var.env}"
  }
}

resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Create PostgreSQL instance
resource "aws_db_instance" "postgres" {
  identifier        = "streamlit-db-${var.env}"
  engine            = "postgres"
  engine_version    = "16.13"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [var.rds_sg_id]

  skip_final_snapshot = true
  publicly_accessible = false # no Internet access
}

# Record the database name
resource "aws_ssm_parameter" "db_name_record" {
  name        = "/${var.env}/database/name"
  description = "Database Name"
  type        = "String"
  value       = aws_db_instance.postgres.db_name
  overwrite   = true
}

# Record the database username
resource "aws_ssm_parameter" "db_username_record" {
  name        = "/${var.env}/database/username"
  description = "Database Master Username"
  type        = "String"
  value       = aws_db_instance.postgres.username
  overwrite   = true
}

# Record password in AWS SSM Parameter Store 
resource "aws_ssm_parameter" "db_password_record" {
  name        = "/${var.env}/database/password"
  description = "Database password for ${var.env} environment"
  type        = "SecureString"
  value       = aws_db_instance.postgres.password
}

# Record the database endpoint
resource "aws_ssm_parameter" "db_endpoint_record" {
  name      = "/${var.env}/database/endpoint"
  type      = "String"
  value     = aws_db_instance.postgres.address
  overwrite = true
}
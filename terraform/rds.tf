# Об'єднуємо наші дві приватні підмережі в одну групу для бази даних
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "main-db-subnet-group-${var.env}"
  subnet_ids = [aws_subnet.db_private_1.id, aws_subnet.db_private_2.id]

  tags = {
    Name = "PostgreSQL Subnet Group ${var.env}"
  }
}

# Генеруємо випадковий пароль
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Зберігаємо пароль в AWS SSM Parameter Store 
resource "aws_ssm_parameter" "db_password" {
  name        = "/${var.env}/database/password"
  description = "Database password for ${var.env} environment"
  type        = "SecureString"
  value       = random_password.db_password.result
}

# Створення інстансу бази даних PostgreSQL
resource "aws_db_instance" "postgres" {
  identifier        = "conduit-db-${var.env}"
  engine            = "postgres"
  engine_version    = "16.13"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "conduit"
  username = var.db_username
  password = aws_ssm_parameter.db_password.value

  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  skip_final_snapshot = true
  publicly_accessible = false # Критично для безпеки: немає доступу з Інтернету
}
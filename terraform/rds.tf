# Об'єднуємо наші дві приватні підмережі в одну групу для бази даних
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "main-db-subnet-group-${var.env}"
  subnet_ids = [aws_subnet.db_private_1.id, aws_subnet.db_private_2.id]

  tags = {
    Name = "PostgreSQL Subnet Group ${var.env}"
  }
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
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  skip_final_snapshot = true
  publicly_accessible = false # Критично для безпеки: немає доступу з Інтернету
}
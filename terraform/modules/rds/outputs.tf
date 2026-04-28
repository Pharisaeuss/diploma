output "db_address" {
  description = "The address of the RDS instance"
  value       = aws_db_instance.postgres.address
}

output "db_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.postgres.arn
}
output "vpc_id" {
  value = data.aws_vpc.default.id
}

output "asg_subnet_ids" {
  value = [aws_subnet.asg_subnet_1.id, aws_subnet.asg_subnet_2.id]
}

output "alb_subnet_ids" {
  value = [aws_subnet.alb_subnet_1.id, aws_subnet.alb_subnet_2.id]
}

output "db_subnet_ids" {
  value = [aws_subnet.db_private_1.id, aws_subnet.db_private_2.id]
}

output "asg_sg_id" {
  value = aws_security_group.asg_sg.id
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "rds_sg_id" {
  value = aws_security_group.rds_sg.id
}
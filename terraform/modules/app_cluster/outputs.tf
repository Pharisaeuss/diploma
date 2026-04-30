output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.main_alb.dns_name
}

output "asg_name" {
  description = "The name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app_asg.name
}

output "alb_arn_suffix" {
  description = "The ARN suffix of the Application Load Balancer for CloudWatch metrics"
  value       = aws_lb.main_alb.arn_suffix 
}
# Log group
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/diploma-app-${var.env}"
  retention_in_days = 14 # Зберігаємо логи 14 днів для оптимізації витрат

  tags = {
    Environment = var.env
    Project     = "DevOps-Diploma"
  }
}

# Alarm for high CPU utilization
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "ASG-High-CPU-${var.env}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120 # Check every 2 minutes
  statistic           = "Average"
  threshold           = 80.0
  alarm_description   = "Triggered when ASG average CPU exceeds 80%"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
}

# Alarm for high 5XX errors from ALB
resource "aws_cloudwatch_metric_alarm" "high_5xx_errors" {
  alarm_name          = "ALB-High-5XX-Errors-${var.env}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10 # Alarm if 10+ errors per minute
  alarm_description   = "Triggered on multiple 5XX HTTP errors from backend"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}

# Alarm for high latency 
resource "aws_cloudwatch_metric_alarm" "high_latency" {
  alarm_name          = "ALB-High-Latency-${var.env}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 2.0 # Тривога, якщо середня відповідь довша за 2 секунди
  alarm_description   = "Triggered when backend response time exceeds 2 seconds"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}

# Alarm for high number of DB connections 
resource "aws_cloudwatch_metric_alarm" "high_db_connections" {
  alarm_name          = "RDS-High-Connections-${var.env}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 50 # Залежить від лімітів t3.micro
  alarm_description   = "Triggered on unusually high DB connection count"

  dimensions = {
    DBInstanceIdentifier = var.db_identifier
  }
}

# Dashboard for AWS CloudWatch
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "DevOps-Diploma-Dashboard-${var.env}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.asg_name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "ASG CPU Utilization (%)"
          period  = 60
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "ALB Total HTTP Requests"
          period  = 60
          stat    = "Sum"
        }
      }
    ]
  })
}
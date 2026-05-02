# Log group
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/diploma-app-${var.env}"
  retention_in_days = 14 # Retain logs for 14 days

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
  threshold           = 2.0 # Alarm if average response time exceeds 2 seconds
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
  threshold           = 50 
  alarm_description   = "Triggered on unusually high DB connection count"

  dimensions = {
    DBInstanceIdentifier = var.db_identifier
  }
}

# Dashboard for AWS CloudWatch
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "Infrastructure-Monitoring-Dashboard-${var.env}"

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
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.alb_arn_suffix]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "ALB 5XX Server Errors"
          period  = 60
          stat    = "Sum"
          yAxis   = { left = { min = 0 } }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "ALB Target Response Time (Seconds)"
          period  = 60
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.db_identifier]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "RDS Active Database Connections"
          period  = 60
          stat    = "Average"
        }
      }
    ]
  })
}

# Record ASG name
resource "aws_ssm_parameter" "asg_name_record" {
  name  = "/${var.env}/app/asg_name"
  type  = "String"
  value = var.asg_name 
}

# Record DB identifier 
resource "aws_ssm_parameter" "db_identifier_record" {
  name  = "/${var.env}/app/db_identifier"
  type  = "String"
  value = var.db_identifier
}

# Record ALB suffix 
resource "aws_ssm_parameter" "alb_suffix_record" {
  name  = "/${var.env}/app/alb_suffix"
  type  = "String"
  value = var.alb_arn_suffix
}
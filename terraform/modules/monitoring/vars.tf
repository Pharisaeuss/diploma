variable "env" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "eu-central-1"
}

variable "asg_name" {
  description = "Name of the Auto Scaling Group to monitor"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer for metrics"
  type        = string
}

variable "db_identifier" {
  description = "The identifier of the RDS instance for CloudWatch metrics"
  type        = string
}
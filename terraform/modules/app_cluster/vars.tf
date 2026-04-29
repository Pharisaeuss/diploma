variable "region" {
  description = "AWS Region"
  type        = string
}
variable "env" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "machine_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "vpc_id" {
  description = "VPC ID from network module"
  type        = string
}

variable "asg_subnet_id" {
  description = "Subnet ID for the Auto Scaling Group"
  type        = string
}

variable "alb_subnet_ids" {
  description = "List of Subnet IDs for the Application Load Balancer"
  type        = list(string)
}

variable "asg_sg_id" {
  description = "Security Group ID for the ASG"
  type        = string
}

variable "alb_sg_id" {
  description = "Security Group ID for the ALB"
  type        = string
}

variable "iam_instance_profile_name" {
  description = "Name of the IAM instance profile for EC2"
  type        = string
}

variable "alb_logs_bucket_id" {
  description = "ID of the S3 bucket for ALB logs"
  type        = string
}
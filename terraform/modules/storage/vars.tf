variable "env" {
  description = "Environment name"
  type        = string
}

variable "ec2_role_id" {
  description = "The ID of the EC2 IAM role to attach the S3 policy to"
  type        = string
}
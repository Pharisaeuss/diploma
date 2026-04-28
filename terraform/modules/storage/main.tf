resource "aws_s3_bucket" "alb_logs" {
  bucket_prefix = "my-alb-logs-${var.env}-2026-diploma-"
  force_destroy = true
}

# Add a policy to allow ALB to write logs
resource "aws_s3_bucket_policy" "allow_alb_logging" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/alb-logs/${var.env}/*"
      }
    ]
  })
}

# Bucket for Ansible file transfer
resource "aws_s3_bucket" "ansible_ssm_bucket" {
  bucket_prefix = "ansible-ssm-transfer-${var.env}-"
  force_destroy = true
}

# Allow EC2 server to read and write to this bucket
resource "aws_iam_role_policy" "ssm_s3_policy" {
  name = "ansible_ssm_s3_policy"
  role = var.ec2_role_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.ansible_ssm_bucket.arn,
          "${aws_s3_bucket.ansible_ssm_bucket.arn}/*"
        ]
      },
    ]
  })
}

# Record the bucket name
resource "aws_ssm_parameter" "bucket_name" {
  name      = "/${var.env}/s3/app_bucket_name"
  type      = "String"
  value     = aws_s3_bucket.ansible_ssm_bucket.id
  overwrite = true
}
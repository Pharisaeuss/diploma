# Create the S3 Bucket
resource "aws_s3_bucket" "alb_logs" {
  bucket        = "my-alb-logs-${var.env}-2026-diploma" # Must be globally unique
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

# Data source to get your AWS Account ID automatically
data "aws_caller_identity" "current" {}
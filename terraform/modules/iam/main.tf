resource "aws_iam_role" "ec2_s3_role" {
  name = "ec2-s3-readonly-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "s3_read_only" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "ec2_s3_profile" {
  name = "ec2-s3-profile-${var.env}"
  role = aws_iam_role.ec2_s3_role.name
}

resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Access to SSM Parameter Store for runtime configuration 
resource "aws_iam_role_policy" "ssm_parameter_access" {
  name = "ssm-parameter-access-${var.env}"
  role = aws_iam_role.ec2_s3_role.id 

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        # Restrict to parameters under this env's namespace only
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.env}/*"
      }
    ]
  })
}

# ── 4. IAM policy: allow the instance to read its SSM namespace ───────────────
# data "aws_iam_policy_document" "ssm_read" {
#   statement {
#     effect = "Allow"
#     actions = [
#       "ssm:GetParameter",
#       "ssm:GetParameters",
#       "ssm:GetParametersByPath",
#     ]
#     # Scope to this env only — no cross-env access
#     resources = [
#       "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.env}/*"
#     ]
#   }
# }

# Allow EC2 instances to read secrets from SSM Parameter Store 
# resource "aws_iam_role_policy" "ssm_read_secrets" {
#   name = "ssm-read-secrets-policy-${var.env}"
#   role = aws_iam_role.ec2_s3_role.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "ssm:GetParameter",
#           "ssm:GetParameters"
#         ]
#         Resource = "arn:aws:ssm:${var.region}:*:parameter/${var.env}/*"
#       }
#     ]
#   })
# }
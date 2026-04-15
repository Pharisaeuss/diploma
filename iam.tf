# 1. Create the IAM Role (Trusted Entity: EC2)
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

# 2. Attach the exact AWS Managed Policy mentioned in the article
resource "aws_iam_role_policy_attachment" "s3_read_only" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# 3. Create the Instance Profile (The "Bridge" between IAM and EC2)
resource "aws_iam_instance_profile" "ec2_s3_profile" {
  name = "ec2-s3-profile-${var.env}"
  role = aws_iam_role.ec2_s3_role.name
}
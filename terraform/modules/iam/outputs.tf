output "ec2_role_id" {
  value = aws_iam_role.ec2_s3_role.id
}

output "ec2_instance_profile_name" {
  value = aws_iam_instance_profile.ec2_s3_profile.name
}
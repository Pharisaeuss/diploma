output "app_node_role_id" {
  value = aws_iam_role.app_node_role.id
}

output "app_node_instance_profile_name" {
  value = aws_iam_instance_profile.app_node_profile.name
}
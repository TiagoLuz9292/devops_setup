output "admin_role_name" {
  value = aws_iam_role.admin_role.name
}

output "admin_instance_profile_name" {
  value = aws_iam_instance_profile.admin_instance_profile.name
}

output "admin_instance_profile_name" {
  value = aws_iam_instance_profile.master_instance_profile.name
}
output "admin_instance_profile_name" {
  value = aws_iam_instance_profile.worker_instance_profile.name
}

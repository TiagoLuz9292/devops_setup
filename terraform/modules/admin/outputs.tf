output "vpc_id" {
  value = aws_vpc.main.id
}

output "route_table_id" {
  value = aws_route_table.main.id
}

output "subnet_id" {
  value = aws_subnet.main.id
}

output "security_group_id" {
  value = aws_security_group.admin.id
}

output "instance_id" {
  value = aws_instance.admin.id
}

output "instance_public_ip" {
  value = aws_instance.admin.public_ip
}

output "iam_role_name" {
  value = aws_iam_role.admin_role.name
}

output "iam_policy_name" {
  value = aws_iam_policy.admin_policy.name
}

output "iam_instance_profile_name" {
  value = aws_iam_instance_profile.admin_instance_profile.name
}
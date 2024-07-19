output "admin_subnet_id" {
  value = aws_subnet.admin.id
}

output "instance_security_group_id" {
  value = aws_security_group.instance.id
}
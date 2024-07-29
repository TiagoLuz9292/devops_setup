# modules/networking/outputs.tf

output "public_subnet_id1" {
  value = aws_subnet.public1.id
}

output "public_subnet_id2" {
  value = aws_subnet.public2.id
}

output "admin_subnet_id" {
  value = aws_subnet.admin.id
}

output "instance_security_group_id" {
  value = aws_security_group.instance.id
}

output "lb_target_group_arn" {
  value = aws_lb_target_group.k8s_target_group.arn
}

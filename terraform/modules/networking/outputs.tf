output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id1" {
  value = aws_subnet.public1.id
}

output "public_subnet_id2" {
  value = aws_subnet.public2.id
}

output "route_table_id" {
  value = aws_route_table.routetable.id
}

output "instance_security_group_id" {
  value = aws_security_group.instance.id
}

output "elb_security_group_id" {
  value = aws_security_group.elb.id
}

output "lb_target_group_arn" {
  value = aws_lb_target_group.k8s_target_group.arn
}

output "vpc_cidr" {
  value = var.vpc_cidr
}
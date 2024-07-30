output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet1_id" {
  value = aws_subnet.public1.id
}

output "subnet2_id" {
  value = aws_subnet.public2.id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "instance_security_group_id" {
  value = aws_security_group.instance.id
}

output "route_table_id" {
  value = aws_route_table.routetable.id
}
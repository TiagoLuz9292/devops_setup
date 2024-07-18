# Outputs for the VPC, subnet, and instances.

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "admin_subnet_id" {
  description = "ID of the admin subnet"
  value       = aws_subnet.admin.id
}

output "master_instance_id" {
  description = "ID of the master EC2 instance"
  value       = aws_instance.master.id
}

output "master_instance_ip" {
  description = "Public IP of the master EC2 instance"
  value       = aws_instance.master.public_ip
}


output "admin_instance_id" {
  description = "ID of the admin EC2 instance"
  value       = aws_instance.admin.id
}

output "admin_public_ip" {
  description = "Public IP of the admin EC2 instance"
  value       = aws_eip.admin_eip.public_ip
}


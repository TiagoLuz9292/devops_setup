# Outputs for the VPC, subnet, and instances.

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "master_instance_id" {
  description = "ID of the master EC2 instance"
  value       = aws_instance.master.id
}

output "master_instance_ip" {
  description = "Public IP of the master EC2 instance"
  value       = aws_instance.master.public_ip
}

# Outputs for the worker node
output "worker_instance_id" {
  description = "ID of the worker EC2 instance"
  value       = aws_instance.worker.id
}

output "worker_instance_ip" {
  description = "Public IP of the worker EC2 instance"
  value       = aws_instance.worker.public_ip
}

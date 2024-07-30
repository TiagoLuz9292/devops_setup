output "master_instance_id" {
  value = aws_instance.master.id
}

output "master_instance_public_ip" {
  value = aws_eip.master_eip.public_ip
}

output "worker_launch_template_id" {
  value = aws_launch_template.worker.id
}

output "instance_id" {
  value = aws_instance.instance.id
}

output "instance_public_ip" {
  value = aws_eip.eip.public_ip
}

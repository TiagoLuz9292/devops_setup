# Output for Admin Server Private IP
output "admin_server_private_ip" {
  value = aws_instance.admin.private_ip
}

# Output for Admin Server Public IP
output "admin_server_public_ip" {
  value = aws_eip.admin_eip.public_ip
}
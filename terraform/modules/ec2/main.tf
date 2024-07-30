resource "aws_instance" "instance" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  key_name                    = var.key_name
  associate_public_ip_address = var.associate_public_ip_address
  iam_instance_profile        = var.iam_instance_profile

  tags = var.tags
}

resource "aws_eip" "eip" {
  instance = aws_instance.instance.id
}

resource "null_resource" "provision_instance" {
  depends_on = [aws_instance.instance]

  provisioner "local-exec" {
    command = var.provision_command
  }
}

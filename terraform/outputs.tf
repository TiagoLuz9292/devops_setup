output "vpc_id" {
    description = "ID of the VPC"
    value       = aws_vpc.main.id
  }
  
  output "subnet_id" {
    description = "ID of the public subnet"
    value       = aws_subnet.public.id
  }
  
  output "web1_instance_id" {
    description = "ID of the first EC2 instance"
    value       = aws_instance.web1.id
  }
  
  output "web2_instance_id" {
    description = "ID of the second EC2 instance"
    value       = aws_instance.web2.id
  }
  
  output "web1_instance_ip" {
    description = "Public IP of the first EC2 instance"
    value       = aws_instance.web1.public_ip
  }
  
  output "web2_instance_ip" {
    description = "Public IP of the second EC2 instance"
    value       = aws_instance.web2.public_ip
  }
  
  output "bucket_name" {
    description = "Name of the S3 bucket"
    value       = aws_s3_bucket.app_bucket.bucket
  }
output "master_instance_id" {
  value = aws_instance.master.id
}

output "master_instance_public_ip" {
  value = aws_eip.master_eip.public_ip
}

output "worker_launch_template_id" {
  value = aws_launch_template.worker.id
}

output "asg_name" {
  value = aws_autoscaling_group.k8s_asg.name
}

output "scale_out_policy_arn" {
  value = aws_autoscaling_policy.scale_out_policy.arn
}

output "scale_in_policy_arn" {
  value = aws_autoscaling_policy.scale_in_policy.arn
}
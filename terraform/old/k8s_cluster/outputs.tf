output "asg_name" {
  value = aws_autoscaling_group.k8s_asg.name
}

output "scale_out_policy_arn" {
  value = aws_autoscaling_policy.scale_out_policy.arn
}

output "scale_in_policy_arn" {
  value = aws_autoscaling_policy.scale_in_policy.arn
}
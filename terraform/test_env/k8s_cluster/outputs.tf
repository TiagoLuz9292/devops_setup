# Output the name of the auto-scaling group
output "asg_name" {
  value = aws_autoscaling_group.k8s_asg.name
}

# Output the ARN of the scale-out policy
output "scale_out_policy_arn" {
  value = aws_autoscaling_policy.scale_out_policy.arn
}

# Output the ARN of the scale-in policy
output "scale_in_policy_arn" {
  value = aws_autoscaling_policy.scale_in_policy.arn
}

# Output for Auto Scaling Role ARN
output "autoscaling_role_arn" {
  value = aws_iam_role.autoscaling_role.arn
}

# Output for High CPU Alarm ARN
output "high_cpu_alarm_arn" {
  value = aws_cloudwatch_metric_alarm.high_cpu.arn
}

# Output for Low CPU Alarm ARN
output "low_cpu_alarm_arn" {
  value = aws_cloudwatch_metric_alarm.low_cpu.arn
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70

  alarm_description   = "This metric monitors the average CPU usage for the ASG."
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.k8s_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_out.arn]
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "low-cpu-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 30

  alarm_description   = "This metric monitors the average CPU usage for the ASG."
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.k8s_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_in.arn]
}
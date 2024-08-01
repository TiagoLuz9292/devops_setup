resource "aws_iam_role" "autoscaling_role" {
  name = "autoscaling_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "autoscaling.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "autoscaling_policy" {
  name   = "autoscaling_policy"
  role   = aws_iam_role.autoscaling_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:UpdateAutoScalingGroup",
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DescribeAlarms",
          "ec2:DescribeInstances"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.period
  statistic           = "Average"
  threshold           = var.high_cpu_threshold
  alarm_description   = "This metric monitors the average CPU usage for the ASG."
  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
  alarm_actions = [var.scale_out_policy_arn]
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "low-cpu-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.period
  statistic           = "Average"
  threshold           = var.low_cpu_threshold
  alarm_description   = "This metric monitors the average CPU usage for the ASG."
  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
  alarm_actions = [var.scale_in_policy_arn]
}

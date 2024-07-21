provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

data "terraform_remote_state" "k8s_cluster" {
  backend = "local"
  config = {
    path = "../k8s_cluster/terraform.tfstate"
  }
}

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
  evaluation_periods  = 21
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 50
  alarm_description   = "This metric monitors the average CPU usage for the ASG."
  dimensions = {
    AutoScalingGroupName = data.terraform_remote_state.k8s_cluster.outputs.asg_name
  }
  alarm_actions = [data.terraform_remote_state.k8s_cluster.outputs.scale_out_policy_arn]
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "low-cpu-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 20
  alarm_description   = "This metric monitors the average CPU usage for the ASG."
  dimensions = {
    AutoScalingGroupName = data.terraform_remote_state.k8s_cluster.outputs.asg_name
  }
  alarm_actions = [data.terraform_remote_state.k8s_cluster.outputs.scale_in_policy_arn]
}
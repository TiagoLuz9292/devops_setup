# Provider configuration for AWS
provider "aws" {
  region = var.region
}

# Fetching the AWS account ID
data "aws_caller_identity" "current" {}

# Fetching remote state data from the Kubernetes cluster configuration
data "terraform_remote_state" "k8s_cluster" {
  backend = "local"
  config = {
    path = "../k8s_cluster/terraform.tfstate"
  }
}

# IAM Role for Auto Scaling
# This role allows Auto Scaling to interact with CloudWatch and EC2
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

# IAM Policy for Auto Scaling
# This policy grants permissions for Auto Scaling to describe, update, and monitor the Auto Scaling group
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

# CloudWatch Alarm for High CPU Utilization
# This alarm triggers when the average CPU usage of the Auto Scaling group exceeds the threshold
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
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

# CloudWatch Alarm for Low CPU Utilization
# This alarm triggers when the average CPU usage of the Auto Scaling group falls below the threshold
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

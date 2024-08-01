provider "aws" {
  region = var.region
}


data "terraform_remote_state" "k8s_cluster" {
  backend = "local"
  config = {
    path = "../k8s_cluster/terraform.tfstate"
  }
}


resource "aws_iam_role" "lambda_iam_role" {
  name = "lambda_iam_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambda_policy"
  role   = aws_iam_role.lambda_iam_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "autoscaling:CompleteLifecycleAction",
          "autoscaling:DescribeAutoScalingInstances",
          "ec2:DescribeInstances",
          "logs:*"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "drain_node" {
  filename         = "lambda_function.zip" # Adjust this path
  function_name    = "drain_node"
  role             = aws_iam_role.lambda_iam_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = filebase64sha256("lambda_function.zip")
  runtime          = "python3.8"
  timeout          = 60
}

resource "aws_sns_topic" "asg_lifecycle_notifications" {
  name = "ASG-Lifecycle-Notifications"
}

resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.asg_lifecycle_notifications.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.drain_node.arn
}

resource "aws_autoscaling_lifecycle_hook" "drain_hook" {
  name                   = "DrainHook"
  autoscaling_group_name = data.terraform_remote_state.k8s_cluster.outputs.asg_name
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
  heartbeat_timeout      = 3600
  default_result         = "CONTINUE"
  notification_target_arn = aws_sns_topic.asg_lifecycle_notifications.arn
  role_arn                = aws_iam_role.autoscaling_role.arn
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.drain_node.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.asg_lifecycle_notifications.arn
}


resource "aws_iam_role" "autoscaling_role" {
  name = "autoscaling_role_new"

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
  name = "autoscaling_policy"
  role = aws_iam_role.autoscaling_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sns:Publish"
        ],
        Resource = aws_sns_topic.asg_lifecycle_notifications.arn
      }
    ]
  })
}
resource "aws_lambda_function" "run_ansible_playbook" {
  function_name = "RunAnsiblePlaybook"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  filename      = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      PRIVATE_KEY_PATH = "/root/.ssh/my-key-pair"
      INVENTORY_PATH   = "/root/project/devops/kubernetes/inventory"
      PLAYBOOK_PATH    = "/root/project/devops/ansible/playbooks/kubernetes/setup_kubernetes_worker.yaml"
    }
  }
}

resource "aws_lambda_function_event_invoke_config" "run_ansible_playbook_config" {
  function_name = aws_lambda_function.run_ansible_playbook.function_name
  maximum_retry_attempts = 0
  maximum_event_age_in_seconds = 60
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.run_ansible_playbook.function_name
  principal     = "events.amazonaws.com"
}

resource "aws_cloudwatch_event_rule" "ec2_instance_launch" {
  name        = "EC2InstanceLaunchRule"
  description = "Triggers when an EC2 instance is launched by an auto-scaling group"
  event_pattern = jsonencode({
    "source": [
      "aws.autoscaling"
    ],
    "detail-type": [
      "EC2 Instance Launch Successful"
    ],
    "detail": {
      "AutoScalingGroupName": [
        "${aws_autoscaling_group.k8s_asg.name}"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.ec2_instance_launch.name
  target_id = "RunAnsiblePlaybook"
  arn       = aws_lambda_function.run_ansible_playbook.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_invoke_lambda" {
  statement_id  = "AllowCloudWatchInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.run_ansible_playbook.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_instance_launch.arn
}
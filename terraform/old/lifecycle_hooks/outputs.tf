output "sns_topic_arn" {
  description = "ARN of the SNS topic for ASG lifecycle notifications."
  value       = aws_sns_topic.asg_lifecycle_notifications.arn
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function to drain nodes."
  value       = aws_lambda_function.drain_node.arn
}

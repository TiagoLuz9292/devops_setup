resource "aws_launch_template" "worker" {
  name_prefix   = "k8s-worker-"
  image_id      = "ami-052387465d846f3fc"  # Change to an appropriate AMI ID for your region
  instance_type = "t3.medium"
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.instance.id]
  }


  tag_specifications {
    resource_type = "instance"
    tags = {
      Name  = "K8s-Worker"
      Group = "Kubernetes"
    }
  }
}

resource "aws_autoscaling_group" "k8s_asg" {
  desired_capacity     = 2
  max_size             = 4
  min_size             = 2
  vpc_zone_identifier  = [aws_subnet.public.id, aws_subnet.public2.id]

  target_group_arns = [aws_lb_target_group.k8s_target_group.arn]

  tag {
    key                 = "Name"
    value               = "K8s-Worker"
    propagate_at_launch = true
  }

  mixed_instances_policy {
    instances_distribution {
      on_demand_allocation_strategy            = "prioritized"
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 100
      spot_allocation_strategy                 = "capacity-optimized"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.worker.id
        version            = "$Latest"
      }

      override {
        instance_type = "t3.medium"
      }
    }
  }
}

resource "aws_autoscaling_lifecycle_hook" "worker_launch_hook" {
  name                   = "worker-launch-hook"
  autoscaling_group_name = aws_autoscaling_group.k8s_asg.name
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_LAUNCHING"
  default_result         = "CONTINUE"
  heartbeat_timeout      = 3600
  notification_target_arn = aws_sns_topic.autoscaling_sns.arn
  role_arn               = aws_iam_role.autoscaling_role.arn
}

# Add Scaling Policies
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.k8s_asg.name
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.k8s_asg.name
}


resource "aws_sns_topic" "autoscaling_sns" {
  name = "autoscaling-sns"

  tags = {
    Name = "autoscaling-sns"
  }
}

resource "aws_sqs_queue" "autoscaling_sqs" {
  name = "autoscaling-sqs"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = "*",
        Action = "sqs:SendMessage",
        Resource = "arn:aws:sqs:eu-north-1:${data.aws_caller_identity.current.account_id}:autoscaling-sqs",
        Condition = {
          ArnEquals = {
            "aws:SourceArn": "arn:aws:sns:eu-north-1:${data.aws_caller_identity.current.account_id}:autoscaling-sns"
          }
        }
      }
    ]
  })
}



resource "aws_sns_topic_subscription" "autoscaling_sns_subscription" {
  topic_arn = aws_sns_topic.autoscaling_sns.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.autoscaling_sqs.arn
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
        Effect = "Allow",
        Action = [
          "sns:Publish",
          "sqs:SendMessage"
        ],
        Resource = [
          aws_sns_topic.autoscaling_sns.arn,
          aws_sqs_queue.autoscaling_sqs.arn
        ]
      }
    ]
  })
}
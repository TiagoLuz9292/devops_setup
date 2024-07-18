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
  desired_capacity     = 3
  max_size             = 4
  min_size             = 3
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

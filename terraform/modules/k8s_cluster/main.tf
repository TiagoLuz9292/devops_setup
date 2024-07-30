resource "aws_instance" "master" {
  ami                         = var.master_ami
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  iam_instance_profile        = var.master_instance_profile

  tags = {
    Name  = var.master_instance_name
    Group = "Kubernetes"
  }
}

resource "aws_launch_template" "worker" {
  name_prefix      = "k8s-worker-"
  image_id         = var.worker_ami
  instance_type    = var.instance_type
  key_name         = var.key_name

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.security_group_id]
  }

  iam_instance_profile {
    name = var.worker_instance_profile
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name  = var.worker_instance_name
      Group = "Kubernetes"
    }
  }

  user_data = base64encode(var.worker_user_data)
}

resource "aws_autoscaling_group" "k8s_asg" {
  depends_on = [null_resource.provision_master]

  name                 = "k8s_asg"
  desired_capacity     = var.desired_capacity
  max_size             = var.max_size
  min_size             = var.min_size
  vpc_zone_identifier  = var.subnet_ids

  target_group_arns = [var.lb_target_group_arn]

  tag {
    key                 = "Name"
    value               = var.worker_instance_name
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
        instance_type = var.instance_type
      }
    }
  }
}

resource "aws_eip" "master_eip" {
  instance = aws_instance.master.id
}

resource "null_resource" "provision_master" {
  depends_on = [aws_instance.master]

  provisioner "local-exec" {
    command = <<EOT
      bash /home/ec2-user/devops_setup/terraform/environments/${var.environment}/provision_master.sh ${var.environment} ${aws_instance.master.private_ip} ${var.private_key_path} ${var.region}
    EOT
  }
}

resource "null_resource" "update_inventory" {
  depends_on = [aws_instance.master]

  provisioner "local-exec" {
    command = var.update_inventory_command
  }

  triggers = {
    master_ip = aws_eip.master_eip.public_ip
  }
}
resource "aws_autoscaling_policy" "scale_out_policy" {
  name                   = "scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.k8s_asg.name
}

resource "aws_autoscaling_policy" "scale_in_policy" {
  name                   = "scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.k8s_asg.name
}
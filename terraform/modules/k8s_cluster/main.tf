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

resource "aws_lb_target_group" "k8s_target_group" {
  name        = "dev-k8s-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 2
  }

  tags = {
    Name = "dev-k8s-tg"
  }
}


resource "aws_autoscaling_group" "k8s_asg" {
  name                 = "k8s_asg"
  desired_capacity     = var.desired_capacity
  max_size             = var.max_size
  min_size             = var.min_size
  vpc_zone_identifier  = var.subnet_ids
   target_group_arns    = [aws_lb_target_group.k8s_target_group.arn]

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
      #!/bin/bash
      set -e

      ENVIRONMENT="${var.environment}"
      MASTER_IP=${aws_instance.master.private_ip}
      PRIVATE_KEY_PATH="/home/ec2-user/.ssh/my-key-pair"
      AWS_REGION="eu-north-1"
      PARAMETER_NAME="k8s-join-command"

      # Ensure correct permissions for the private key
      chmod 600 $PRIVATE_KEY_PATH
      eval "$(ssh-agent -s)"
      ssh-add $PRIVATE_KEY_PATH

      # Wait until the instance is available
      while ! nc -z -w5 $MASTER_IP 22; do
        echo "Waiting for instance to be available at IP $MASTER_IP..."
        sleep 10
      done

      # Add the master IP to known hosts to avoid SSH prompt
      ssh-keygen -R $MASTER_IP -f ~/.ssh/known_hosts || true
      ssh-keyscan -H $MASTER_IP >> ~/.ssh/known_hosts

      # Test SSH connection
      echo "Testing SSH connection to master..."
      ssh -o StrictHostKeyChecking=no -i $PRIVATE_KEY_PATH ec2-user@$MASTER_IP "echo 'SSH connection successful'"

      # Run the script on the admin server to execute the Ansible playbook
      echo "Starting the Ansible Playbook for Kubernetes installation on master"
      echo "private key path: $PRIVATE_KEY_PATH"
      bash /home/ec2-user/devops_setup/ansible/playbooks/kubernetes/setup_kubernetes_cluster.sh $MASTER_IP $PRIVATE_KEY_PATH > terraform_provision_master.log 2>&1
      if [ $? -ne 0 ]; then
        echo "Failed to run setup_kubernetes_cluster.sh. Check terraform_provision_master.log for details."
        exit 1
      fi

      # Run the Ansible playbook to configure kubectl authentication
      echo "Starting the Ansible Playbook for kubectl authentication setup"
      bash /home/ec2-user/devops_setup/ansible/playbooks/kubernetes/setup_kubectl_auth.sh $MASTER_IP $PRIVATE_KEY_PATH > kubeconfig_setup.log 2>&1
      if [ $? -ne 0 ]; then
        echo "Failed to run setup_kubectl_auth.sh. Check kubeconfig_setup.log for details."
        exit 1
      fi

      # Retrieve the join command
      JOIN_COMMAND=$(ssh -o StrictHostKeyChecking=no -i $PRIVATE_KEY_PATH ec2-user@$MASTER_IP "sudo kubeadm token create --print-join-command")

      # Store the join command in SSM Parameter Store
      aws ssm put-parameter --name $PARAMETER_NAME --value "$JOIN_COMMAND" --type "String" --overwrite --region $AWS_REGION
    EOT
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

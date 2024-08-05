
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
    associate_public_ip_address = true
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

  user_data = base64encode(<<-EOF
    #!/bin/bash

    # Ensure the log directory exists
    mkdir -p /home/ec2-user/devops_setup/terraform/production/logs

    LOG_FILE="/home/ec2-user/devops_setup/terraform/production/logs/terraform_provision_workers.log"

    exec > $LOG_FILE 2>&1

    echo "Starting worker setup script" > $LOG_FILE 2>&1


    # Install necessary packages
    sudo yum update -y >> $LOG_FILE 2>&1
    sudo yum install -y jq dnf-utils >> $LOG_FILE 2>&1


  

    # Update all packages
    sudo dnf update -y >> $LOG_FILE 2>&1

    # Disable swap
    sudo swapoff -a >> $LOG_FILE 2>&1

    # Load kernel modules
    echo -e "overlay\nbr_netfilter" | sudo tee /etc/modules-load.d/k8s.conf >> $LOG_FILE 2>&1
    sudo modprobe overlay >> $LOG_FILE 2>&1
    sudo modprobe br_netfilter >> $LOG_FILE 2>&1

    # Set system configurations for Kubernetes
    echo -e "net.bridge.bridge-nf-call-iptables  = 1\nnet.bridge.bridge-nf-call-ip6tables = 1\nnet.ipv4.ip_forward                 = 1" | sudo tee /etc/sysctl.d/k8s.conf >> $LOG_FILE 2>&1
    sudo sysctl --system >> $LOG_FILE 2>&1

    # Install containerd
    wget https://github.com/containerd/containerd/releases/download/v1.6.2/containerd-1.6.2-linux-amd64.tar.gz -O /tmp/containerd-1.6.2-linux-amd64.tar.gz >> $LOG_FILE 2>&1
    sudo tar -xvf /tmp/containerd-1.6.2-linux-amd64.tar.gz -C /usr/local >> $LOG_FILE 2>&1
    sudo wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -O /etc/systemd/system/containerd.service >> $LOG_FILE 2>&1
    sudo systemctl enable --now containerd >> $LOG_FILE 2>&1

    # Install runc
    sudo wget https://github.com/opencontainers/runc/releases/download/v1.1.9/runc.amd64 -O /usr/local/sbin/runc >> $LOG_FILE 2>&1
    sudo chmod 755 /usr/local/sbin/runc >> $LOG_FILE 2>&1

    # Install CNI plugins
    sudo mkdir -p /opt/cni/bin >> $LOG_FILE 2>&1
    wget https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-amd64-v1.1.1.tgz -O /tmp/cni-plugins-linux-amd64-v1.1.1.tgz >> $LOG_FILE 2>&1
    sudo tar -xvf /tmp/cni-plugins-linux-amd64-v1.1.1.tgz -C /opt/cni/bin >> $LOG_FILE 2>&1

    # Configure containerd
    sudo mkdir -p /etc/containerd >> $LOG_FILE 2>&1
    sudo containerd config default | sudo tee /etc/containerd/config.toml >> $LOG_FILE 2>&1
    sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml >> $LOG_FILE 2>&1
    sudo sed -i 's|k8s.gcr.io/pause:3.6|registry.k8s.io/pause:3.2|' /etc/containerd/config.toml >> $LOG_FILE 2>&1
    sudo systemctl restart containerd >> $LOG_FILE 2>&1

    # Set SELinux to permissive mode
    sudo setenforce 0 >> $LOG_FILE 2>&1
    sudo sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config >> $LOG_FILE 2>&1

    # Add Kubernetes yum repository without exclude
    echo -e "[kubernetes]\nname=Kubernetes\nbaseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/\nenabled=1\ngpgcheck=1\ngpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key" | sudo tee /etc/yum.repos.d/kubernetes.repo >> $LOG_FILE 2>&1

    # Install Kubernetes packages
    sudo dnf install -y kubelet kubeadm kubectl >> $LOG_FILE 2>&1

    # Add exclude parameter to Kubernetes yum repository
    echo 'exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni' | sudo tee -a /etc/yum.repos.d/kubernetes.repo >> $LOG_FILE 2>&1

    # Enable and start kubelet
    sudo systemctl enable --now kubelet >> $LOG_FILE 2>&1

    # Install iproute package
    sudo dnf install -y iproute >> $LOG_FILE 2>&1

    # Install iproute-tc package
    sudo dnf install -y iproute-tc >> $LOG_FILE 2>&1

    # Retrieve the join command from SSM Parameter Store
    JOIN_COMMAND=$(aws ssm get-parameter --name "k8s-join-command" --with-decryption --query "Parameter.Value" --output text --region eu-north-1) >> $LOG_FILE 2>&1

    echo "Join command retrieved: $JOIN_COMMAND" >> $LOG_FILE 2>&1

    echo "Executing join command" >> $LOG_FILE 2>&1

    sudo export JOIN_COMMAND

    eval sudo $JOIN_COMMAND --v=5 >> $LOG_FILE 2>&1

    echo "Worker setup script completed" >> $LOG_FILE 2>&1

  EOF
  )
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
  depends_on = [null_resource.provision_master]

  name                 = "k8s_asg"
  desired_capacity     = var.desired_capacity
  max_size             = var.max_size
  min_size             = var.min_size
  vpc_zone_identifier  = var.subnet_ids
   target_group_arns   = var.target_group_arns

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


# Local-exec to update the inventory file
resource "null_resource" "update_inventory" {
  depends_on = [aws_instance.master]

  provisioner "local-exec" {
    command = <<-EOT
      #!/bin/bash
      ENVIRONMENT="${var.environment}"
      bash /home/ec2-user/devops_setup/ansible/inventory/generate_inventory_v2.sh $ENVIRONMENT > terraform_inventory_creation.log 2>&1
    EOT
  }

  triggers = {
    master_ip = aws_eip.master_eip.public_ip
  }
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
      bash /home/ec2-user/devops_setup/ansible/playbooks/kubernetes/setup_kubernetes_cluster.sh $ENVIRONMENT $MASTER_IP $PRIVATE_KEY_PATH > terraform_provision_master.log 2>&1
      if [ $? -ne 0 ]; then
        echo "Failed to run setup_kubernetes_cluster.sh. Check terraform_provision_master.log for details."
        exit 1
      fi

      # Run the Ansible playbook to configure kubectl authentication
      echo "Starting the Ansible Playbook for kubectl authentication setup"
      bash /home/ec2-user/devops_setup/ansible/playbooks/kubernetes/setup_kubectl_auth.sh $ENVIRONMENT $MASTER_IP $PRIVATE_KEY_PATH > kubeconfig_setup.log 2>&1
      if [ $? -ne 0 ]; then
        echo "Failed to run setup_kubectl_auth.sh. Check kubeconfig_setup.log for details."
        exit 1
      fi

      # Retrieve the join command with the private IP
      JOIN_COMMAND=$(< /home/ec2-user/devops_setup/terraform/join_command.sh)

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





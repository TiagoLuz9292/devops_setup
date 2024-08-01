data "terraform_remote_state" "networking" {
  backend = "s3"

  config = {
    bucket         = "terraform-state-2024-1a"
    key            = "networking/vpc_main/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-state-locks"
  }
}

data "terraform_remote_state" "iam" {
  backend = "s3"

  config = {
    bucket         = "terraform-state-2024-1a"
    key            = "iam/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-state-locks"
  }
}



# Create the Kubernetes master instance
resource "aws_instance" "master" {
  ami                           = "ami-052387465d846f3fc"  # Change to an appropriate AMI ID for your region
  instance_type                 = "t3.medium"
  subnet_id                     = data.terraform_remote_state.networking.outputs.public_subnet_id1
  vpc_security_group_ids        = [data.terraform_remote_state.networking.outputs.instance_security_group_id]
  key_name                      = var.key_name
  associate_public_ip_address   = true
  iam_instance_profile          = data.terraform_remote_state.iam.outputs.master_instance_profile_name

  tags = {
    Name  = "K8s-Master"
    Group = "Kubernetes"
  }
}


# Create the worker instances in two subnets for high availability
# Povision worker instances
resource "aws_launch_template" "worker" {
  name_prefix                   = "k8s-worker-"
  image_id                      = "ami-052387465d846f3fc"  # Change to an appropriate AMI ID for your region
  instance_type                 = "t3.medium"
  key_name                      = var.key_name
  iam_instance_profile          = data.terraform_remote_state.iam.outputs.worker_instance_profile_name
  

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [data.terraform_remote_state.networking.outputs.instance_security_group_id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name  = "K8s-Worker"
      Group = "Kubernetes"
    }
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash

    # Ensure the log directory exists
    mkdir -p /home/ec2-user/devops_setup/terraform/production/logs

    LOG_FILE="/home/ec2-user/devops_setup/terraform/production/logs/terraform_provision_workers.log"

    exec > $LOG_FILE 2>&1

    # Install necessary packages
    yum update -y
    yum install -y jq dnf-utils

    

    echo "Starting worker setup script" > $LOG_FILE 2>&1

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
    JOIN_COMMAND=$(aws ssm get-parameter --name "k8s-join-command" --with-decryption --query "Parameter.Value" --output text --region eu-north-1)

    export JOIN_COMMAND

    eval sudo $JOIN_COMMAND

  EOF
  )
}

resource "aws_autoscaling_group" "k8s_asg" {
  depends_on = [null_resource.provision_master]
  
  name                 = "k8s_asg"
  desired_capacity     = 1
  max_size             = 4
  min_size             = 1
  vpc_zone_identifier  = [
    data.terraform_remote_state.networking.outputs.public_subnet_id1, 
    data.terraform_remote_state.networking.outputs.public_subnet_id2
  ]

  target_group_arns = [data.terraform_remote_state.networking.outputs.lb_target_group_arn]

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

# Local-exec to update the inventory file
resource "null_resource" "update_inventory" {
  depends_on = [aws_instance.master]

  provisioner "local-exec" {
    command = <<-EOT
      WORKER_IPS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=K8s-Worker" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].PublicIpAddress" --output text)
      /home/ec2-user/devops_setup/ansible/inventory/generate_inventory.sh
    EOT
  }

  triggers = {
    master_ip = aws_eip.master_eip.public_ip
  }
}

# Provision master instance
resource "null_resource" "provision_master" {
  depends_on = [aws_instance.master]

  provisioner "local-exec" {
    command = <<EOT
      #!/bin/bash
      set -e

      MASTER_IP=${aws_instance.master.private_ip}
      PRIVATE_KEY_PATH=${var.private_key_path}
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




# Allocate Elastic IP for Master Node
resource "aws_eip" "master_eip" {
  instance = aws_instance.master.id
}

# Outputs
output "master_public_ip" {
  value = aws_eip.master_eip.public_ip
}

output "lb_target_group_arn" {
  value = data.terraform_remote_state.networking.outputs.lb_target_group_arn
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
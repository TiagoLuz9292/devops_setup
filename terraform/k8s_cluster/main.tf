# Load networking module outputs
data "terraform_remote_state" "networking" {
  backend = "local"
  config = {
    path = "../networking/terraform.tfstate"
  }
}

# Create the Kubernetes master instance
resource "aws_instance" "master" {
  ami           = "ami-052387465d846f3fc"  # Change to an appropriate AMI ID for your region
  instance_type = "t3.medium"
  subnet_id     = data.terraform_remote_state.networking.outputs.public_subnet_id1
  vpc_security_group_ids = [data.terraform_remote_state.networking.outputs.instance_security_group_id]
  key_name      = var.key_name
  associate_public_ip_address = true

  tags = {
    Name  = "K8s-Master"
    Group = "Kubernetes"
  }
}

# Create the worker instances in two subnets for high availability
resource "aws_launch_template" "worker" {
  name_prefix   = "k8s-worker-"
  image_id      = "ami-052387465d846f3fc"  # Change to an appropriate AMI ID for your region
  instance_type = "t3.medium"
  key_name      = var.key_name

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
}

resource "aws_autoscaling_group" "k8s_asg" {
  desired_capacity     = 2
  max_size             = 4
  min_size             = 2
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
  depends_on = [aws_autoscaling_group.k8s_asg]

  provisioner "local-exec" {
    command = <<-EOT
      WORKER_IPS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=K8s-Worker" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].PublicIpAddress" --output text)
      /root/project/devops/terraform/generate_inventory.sh
    EOT
  }

  triggers = {
    master_ip = aws_eip.master_eip.public_ip
  }
}

# Provision master instance
resource "null_resource" "provision_master" {
  depends_on = [aws_instance.master, null_resource.update_inventory]

  provisioner "local-exec" {
    command = <<EOT
      #!/bin/bash
      set -e

      MASTER_IP=${aws_eip.master_eip.public_ip}
      PRIVATE_KEY_PATH=${var.private_key_path}

      # Wait until the instance is available
      while ! nc -z -w5 $MASTER_IP 22; do
        echo "Waiting for instance to be available at IP $MASTER_IP..."
        sleep 10
      done

      # Add the master IP to known hosts to avoid SSH prompt
      ssh-keyscan -H $MASTER_IP >> ~/.ssh/known_hosts

      # Run the Ansible playbook
      echo "Starting the Ansible Playbook for kubernetes instalation on master"
      bash /root/project/devops/ansible/playbooks/kubernetes/setup_kubernetes_cluster.sh $MASTER_IP $PRIVATE_KEY_PATH > terraform_provision_master.log 2>&1
      if [ $? -ne 0 ]; then
        echo "Failed to run setup_kubernetes_cluster.sh. Check terraform_provision_master.log for details."
        exit 1
      fi

      # Run the Ansible playbook to configure kubectl authentication
      echo "Starting the Ansible Playbook for kubectl authentication setup"
      bash /root/project/devops/ansible/playbooks/kubernetes/setup_kubectl_auth.sh $MASTER_IP $PRIVATE_KEY_PATH > kubeconfig_setup.log 2>&1
      if [ $? -ne 0 ]; then
        echo "Failed to run setup_kubectl_auth.sh. Check kubeconfig_setup.log for details."
        exit 1
      fi
    EOT
  }
}

# Provision worker instances
resource "null_resource" "provision_workers" {
  depends_on = [aws_autoscaling_group.k8s_asg, null_resource.provision_master]

  provisioner "local-exec" {
    command = <<EOT
      #!/bin/bash
      set -e

      MASTER_IP=${aws_eip.master_eip.public_ip}
      PRIVATE_KEY_PATH=${var.private_key_path}
      INVENTORY_PATH="/root/project/devops/kubernetes/inventory"

      # Check if the master node is ready
      while ! ssh -o StrictHostKeyChecking=no -i $PRIVATE_KEY_PATH ec2-user@$MASTER_IP sudo kubectl get nodes; do
        echo "Waiting for Kubernetes master to be ready..."
        sleep 20
      done

      # Get the list of worker node IPs
      WORKER_IPS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=K8s-Worker" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].PublicIpAddress" --output text)

      # Wait for all worker instances to be available
      for WORKER_IP in $WORKER_IPS; do
        echo "Waiting for instance to be available at IP $WORKER_IP..."
        while ! nc -z -w5 $WORKER_IP 22; do
          sleep 10
        done

        # Add the worker IP to known hosts to avoid SSH prompt
        ssh-keyscan -H $WORKER_IP >> ~/.ssh/known_hosts
      done

      # Run the Ansible playbook
      echo "Starting the Ansible Playbook for Kubernetes setup on all worker nodes"
      LOG_FILE="terraform_provision_workers.log"
      bash /root/project/devops/ansible/playbooks/kubernetes/setup_kubernetes_worker.sh $MASTER_IP $PRIVATE_KEY_PATH $WORKER_IP > $LOG_FILE 2>&1
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

output "worker_public_ips" {
  value = aws_instance.worker[*].public_ip
}

output "lb_target_group_arn" {
  value = data.terraform_remote_state.networking.outputs.lb_target_group_arn
}

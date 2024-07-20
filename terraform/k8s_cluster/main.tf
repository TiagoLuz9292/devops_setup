# Load networking module outputs
data "terraform_remote_state" "networking" {
  backend = "local"
  config = {
    path = "../networking/terraform.tfstate"
  }
}

data "terraform_remote_state" "admin" {
  backend = "local"
  config = {
    path = "../admin/terraform.tfstate"
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
  key_name      = var.worker_key_name

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
    # Install necessary packages
    yum update -y
    yum install -y aws-cli jq

    # Retrieve the private key from SSM Parameter Store
    PRIVATE_KEY=$(aws ssm get-parameter --name "WorkerPrivateKey" --with-decryption --query "Parameter.Value" --output text)

    # Create .ssh directory and set permissions
    mkdir -p /home/ec2-user/.ssh
    chmod 700 /home/ec2-user/.ssh

    # Save the private key to a file and set permissions
    echo "$PRIVATE_KEY" > /home/ec2-user/.ssh/key-pair
    chmod 600 /home/ec2-user/.ssh/key-pair
    chown ec2-user:ec2-user /home/ec2-user/.ssh/key-pair

    # Add the admin server to known hosts to avoid SSH prompt
    ssh-keyscan -H ${data.terraform_remote_state.admin.outputs.admin_server_private_ip} >> /home/ec2-user/.ssh/known_hosts

    # Test SSH connection
    ssh -i /home/ec2-user/.ssh/key-pair ec2-user@${data.terraform_remote_state.admin.outputs.admin_server_private_ip} "echo 'SSH connection successful'"

    # Execute the playbook to configure the new EC2 instance
    ssh -i /home/ec2-user/.ssh/key-pair ec2-user@${data.terraform_remote_state.admin.outputs.admin_server_private_ip} "/home/ec2-user/devops_setup/ansible/playbooks/kubernetes/setup_kubernetes_worker.sh"
  EOF
  )
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
      /home/ec2-user/devops_setup/terraform/generate_inventory.sh
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

      MASTER_IP=${aws_instance.master.private_ip}
      PRIVATE_KEY_PATH=${var.private_key_path}

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
      ssh-keygen -R $MASTER_IP || true
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
    EOT
  }
}


# Povision worker instances
resource "null_resource" "provision_workers" {
  depends_on = [aws_autoscaling_group.k8s_asg, null_resource.provision_master]

  provisioner "local-exec" {
    command = <<EOT
      #!/bin/bash
      set -e

      MASTER_IP=${aws_instance.master.private_ip}
      PRIVATE_KEY_PATH=${var.private_key_path}
      INVENTORY_PATH="/home/ec2-user/devops_setup/kubernetes/inventory"

      # Check if the master node is ready
      while ! ssh -o StrictHostKeyChecking=no -i $PRIVATE_KEY_PATH ec2-user@$MASTER_IP sudo kubectl get nodes; do
        echo "Waiting for Kubernetes master to be ready..."
        sleep 20
      done

      # Get the list of worker node IPs
      WORKER_IPS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=K8s-Worker" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].PrivateIpAddress" --output text)

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
      bash /home/ec2-user/devops_setup/ansible/playbooks/kubernetes/setup_kubernetes_worker.sh $MASTER_IP $PRIVATE_KEY_PATH $WORKER_IP > $LOG_FILE 2>&1
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

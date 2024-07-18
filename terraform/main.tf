# VPC (Virtual Private Cloud)
# Creates a VPC with a specified CIDR block.
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "main-vpc"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  availability_zone       = "eu-north-1a"  # Change to an appropriate AZ
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# Public Subnet 2
resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-north-1b"  # Change to an appropriate AZ
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-2"
  }
}


# Admin Subnet
resource "aws_subnet" "admin" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.admin_subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "admin-subnet"
  }
}

# Internet Gateway
# Creates an internet gateway to allow internet access to the instances.

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# Route Table
# Creates a route table and a route to the internet gateway.

resource "aws_route_table" "routetable" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "main-route-table"
  }
}

# Route Table Association for Public Subnet 1
resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.routetable.id
}

# Route Table Association for Public Subnet 2
resource "aws_route_table_association" "public_association2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.routetable.id
}

# Route Table Association for Admin Subnet
resource "aws_route_table_association" "admin_association" {
  subnet_id      = aws_subnet.admin.id
  route_table_id = aws_route_table.routetable.id
}
# Listener to forward from elb to target group

resource "aws_lb_listener" "k8s_listener" {
  load_balancer_arn = aws_lb.k8s_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s_target_group.arn
  }
}


# Target Group

resource "aws_lb_target_group" "k8s_target_group" {
  name        = "k8s-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
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
    Name = "k8s-target-group"
  }
}


# Elastic Load Balancer elb

resource "aws_lb" "k8s_lb" {
  name               = "k8s-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elb.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public2.id]

  enable_deletion_protection = false

  tags = {
    Name = "k8s-lb"
  }
}

# Security Group
# Creates a security group with rules to allow necessary traffic for Kubernetes.

resource "aws_security_group_rule" "allow_elb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.instance.id
  source_security_group_id = aws_security_group.elb.id
}

resource "aws_security_group" "elb" {
  vpc_id = aws_vpc.main.id

  # Allow HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "elb-security-group"
  }
}



resource "aws_security_group" "instance" {
  vpc_id = aws_vpc.main.id

  # Allow SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Kubernetes API server access
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow etcd server client API access
  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow kubelet API access
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Flannel (UDP) access
  ingress {
    from_port   = 8285
    to_port     = 8285
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Node Exporter (for hardware metrics)
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow NodePort range
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "instance-security-group"
  }
}

###########################################################################################
#                          iam-policies                                                   #
###########################################################################################

resource "aws_iam_policy" "s3_read_policy" {
  name        = "S3ReadAccess"
  description = "Policy to grant read access to S3 bucket"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::mybucket",
        "arn:aws:s3:::mybucket/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy" "ec2_full_access_policy" {
  name        = "EC2FullAccess"
  description = "Policy to grant full access to EC2 instances"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}



###########################################################################################
#                          iam-roles                                                      #
###########################################################################################


resource "aws_iam_role" "developer_role" {
  name = "developer-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "developer_s3_policy" {
  role       = aws_iam_role.developer_role.name
  policy_arn = aws_iam_policy.s3_read_policy.arn
}

resource "aws_iam_role_policy_attachment" "developer_ec2_policy" {
  role       = aws_iam_role.developer_role.name
  policy_arn = aws_iam_policy.ec2_full_access_policy.arn
}

resource "aws_iam_instance_profile" "developer_instance_profile" {
  name = "developer-instance-profile"
  role = aws_iam_role.developer_role.name
}

###########################################################################################
# EC2 Instance for Admin server                                                           #
###########################################################################################

# Admin Server
resource "aws_instance" "admin" {
  ami           = "ami-052387465d846f3fc"  # Change to an appropriate AMI ID for your region
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.admin.id
  vpc_security_group_ids = [aws_security_group.instance.id]
  key_name      = var.key_name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user_data.sh.tmpl", {
    user_public_keys = var.user_public_keys
  })

  tags = {
    Name  = "Admin-Server"
    Group = "Admin"
  }
}

# Allocate Elastic IP for Admin Server
resource "aws_eip" "admin_eip" {
  instance = aws_instance.admin.id
}


###########################################################################################
# EC2 Instances for Master and Workers                                                    #
# Creates EC2 instances for the Kubernetes master and worker nodes.                       #
###########################################################################################

# Master Node
resource "aws_instance" "master" {
  ami           = "ami-052387465d846f3fc"  # Change to an appropriate AMI ID for your region
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.instance.id]
  key_name      = var.key_name
  associate_public_ip_address = true


  tags = {
    Name  = "K8s-Master"
    Group = "Kubernetes"
  }
}

# Local-exec to update the inventory file
resource "null_resource" "update_inventory" {
  depends_on = [aws_autoscaling_group.k8s_asg]

  provisioner "local-exec" {
    command = <<EOT
      echo "[all]" > /root/project/devops/kubernetes/inventory
      echo "master ansible_host=${aws_eip.master_eip.public_ip} ansible_user=ec2-user" >> /root/project/devops/kubernetes/inventory
      echo "admin ansible_host=${aws_eip.admin_eip.public_ip} ansible_user=ec2-user" >> /root/project/devops/kubernetes/inventory
      echo "" >> /root/project/devops/kubernetes/inventory
      echo "[master]" >> /root/project/devops/kubernetes/inventory
      echo "master" >> /root/project/devops/kubernetes/inventory
      echo "" >> /root/project/devops/kubernetes/inventory
      echo "[workers]" >> /root/project/devops/kubernetes/inventory

      WORKER_IPS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=K8s-Worker" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].PublicIpAddress" --output text)
      for IP in $WORKER_IPS; do
        echo "worker ansible_host=$IP ansible_user=ec2-user" >> /root/project/devops/kubernetes/inventory
      done

      echo "" >> /root/project/devops/kubernetes/inventory
      echo "[admin]" >> /root/project/devops/kubernetes/inventory
      echo "admin" >> /root/project/devops/kubernetes/inventory
    EOT
  }

  triggers = {
    master_ip = aws_eip.master_eip.public_ip
    admin_ip  = aws_eip.admin_eip.public_ip
  }
}


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

      # Add all existing worker IPs to known hosts to avoid SSH prompt
      for IP in $WORKER_IPS; do
        ssh-keyscan -H $IP >> ~/.ssh/known_hosts
      done

      # Remove the workers section if it exists
      sed -i '/\[workers\]/,/^$/d' $INVENTORY_PATH

      # Add workers to the inventory
      echo "[workers]" >> $INVENTORY_PATH
      for IP in $WORKER_IPS; do
        echo "worker ansible_host=$IP ansible_user=ec2-user" >> $INVENTORY_PATH
      done
      echo "" >> $INVENTORY_PATH

      # Ensure the admin section remains in the inventory
      if ! grep -q '\[admin\]' $INVENTORY_PATH; then
        echo "[admin]" >> $INVENTORY_PATH
        echo "admin ansible_host=${aws_eip.admin_eip.public_ip} ansible_user=ec2-user" >> $INVENTORY_PATH
      fi

      # Run the Ansible playbook for each worker node
      

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
# Provides output values for the VPC, subnet, and instances.
output "master_public_ip" {
  value = aws_eip.master_eip.public_ip
}






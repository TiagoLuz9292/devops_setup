#!/bin/bash

    # Install necessary packages
    yum update -y
    yum install -y jq dnf-utils

    # Ensure the log directory exists
    mkdir -p /home/ec2-user/devops_setup/terraform/production/logs

    LOG_FILE="/home/ec2-user/devops_setup/terraform/production/logs/terraform_provision_workers.log"

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
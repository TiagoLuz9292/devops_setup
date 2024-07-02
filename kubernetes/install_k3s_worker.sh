#!/bin/bash

LOG_FILE=/var/log/k3s_worker_install.log
MASTER_IP=$1
NODE_TOKEN=$2

echo "Disabling SELinux temporarily..." | tee -a $LOG_FILE
sudo setenforce 0

echo "Disabling Docker repository temporarily..." | tee -a $LOG_FILE
sudo sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/docker-ce.repo

echo "Installing container-selinux..." | tee -a $LOG_FILE
sudo dnf install -y container-selinux >> $LOG_FILE 2>&1

echo "Downloading k3s binary..." | tee -a $LOG_FILE
curl -sfL https://github.com/k3s-io/k3s/releases/download/v1.29.6%2Bk3s1/k3s -o /usr/local/bin/k3s >> $LOG_FILE 2>&1
sudo chmod +x /usr/local/bin/k3s

echo "Creating k3s agent service file..." | tee -a $LOG_FILE
sudo tee /etc/systemd/system/k3s-agent.service > /dev/null <<EOF
[Unit]
Description=Lightweight Kubernetes
Documentation=https://k3s.io
After=network.target

[Service]
ExecStart=/usr/local/bin/k3s agent --server https://${MASTER_IP}:6443 --token ${NODE_TOKEN}
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd daemon..." | tee -a $LOG_FILE
sudo systemctl daemon-reload

echo "Starting and enabling k3s agent service..." | tee -a $LOG_FILE
sudo systemctl enable k3s-agent >> $LOG_FILE 2>&1
sudo systemctl start k3s-agent >> $LOG_FILE 2>&1

echo "Re-enabling Docker repository..." | tee -a $LOG_FILE
sudo sed -i 's/enabled=0/enabled=1/' /etc/yum.repos.d/docker-ce.repo

echo "Re-enabling SELinux..." | tee -a $LOG_FILE
sudo setenforce 1

echo "Verifying k3s agent service status..." | tee -a $LOG_FILE
sudo systemctl status k3s-agent | tee -a $LOG_FILE

echo "k3s worker node installation complete" | tee -a $LOG_FILE
#!/bin/bash

# Check if the environment parameter is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <environment> <master_ip> <private_key_path>"
  exit 1
fi

ENVIRONMENT=$1
MASTER_IP=$2
PRIVATE_KEY_PATH=$3

INVENTORY_DIR="/home/ec2-user/devops_setup/ansible/inventory/${ENVIRONMENT}_inventory"
K8S_PLAYBOOK_DIR="/home/ec2-user/devops_setup/ansible/playbooks/kubernetes"

# Ensure the private key has correct permissions
chmod 600 $PRIVATE_KEY_PATH
eval "$(ssh-agent -s)"
ssh-add $PRIVATE_KEY_PATH

# Run the Ansible playbook with the correct inventory file
ansible-playbook -i ${INVENTORY_DIR} ${K8S_PLAYBOOK_DIR}/setup_kubernetes_cluster.yaml -v
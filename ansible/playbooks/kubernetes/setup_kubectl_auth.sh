#!/bin/bash

# Check if the environment parameter is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <environment>"
  exit 1
fi

ENVIRONMENT=$1

echo "Running playbook with environment: $ENVIRONMENT"

# Define the inventory directory and the playbook directory
INVENTORY_DIR="/home/ec2-user/devops_setup/ansible/inventory/${ENVIRONMENT}_inventory"
K8S_PLAYBOOK_DIR="/home/ec2-user/devops_setup/ansible/playbooks/kubernetes"

# Extract master private IP from the inventory
MASTER_PRIVATE_IP=$(grep -A1 "\[${ENVIRONMENT}_master\]" ${INVENTORY_DIR}/inventory | tail -n1 | awk '{print $2}' | cut -d'=' -f2)

# Check if the IP was extracted successfully
if [ -z "$MASTER_PRIVATE_IP" ]; then
  echo "Failed to extract master private IP from inventory."
  exit 1
fi

# Run the Ansible playbook with the extracted private IP and environment variable
ansible-playbook -i ${INVENTORY_DIR}/inventory ${K8S_PLAYBOOK_DIR}/setup_kubectl_auth.yaml --extra-vars "master_private_ip=${MASTER_PRIVATE_IP} env=${ENVIRONMENT}" -v


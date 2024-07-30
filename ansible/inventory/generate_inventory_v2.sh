#!/bin/bash

# Check if the environment parameter is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <environment>"
  exit 1
fi

ENVIRONMENT=$1

# Define the directory for inventory files
INVENTORY_DIR="/home/ec2-user/devops_setup/ansible/inventory/${ENVIRONMENT}_inventory"

# Ensure the directory exists
mkdir -p ${INVENTORY_DIR}

# Fetch the private IP of the master node
MASTER_PRIVATE_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=K8s-Master-${ENVIRONMENT}" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].PrivateIpAddress" --output text)

# Fetch the private IP of the admin node
ADMIN_PRIVATE_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=admin-${ENVIRONMENT}" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].PrivateIpAddress" --output text)

# Fetch the private IPs of the worker nodes
WORKER_PRIVATE_IPS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=K8s-Worker-${ENVIRONMENT}" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].PrivateIpAddress" --output text)

# Path to the inventory file
INVENTORY_FILE="${INVENTORY_DIR}/inventory"

# Generate the inventory file
echo "[${ENVIRONMENT}_all]" > ${INVENTORY_FILE}
echo "master ansible_host=${MASTER_PRIVATE_IP} ansible_user=ec2-user" >> ${INVENTORY_FILE}
echo "admin ansible_host=${ADMIN_PRIVATE_IP} ansible_user=ec2-user" >> ${INVENTORY_FILE}
COUNTER=1
for IP in $WORKER_PRIVATE_IPS; do
  echo "worker${COUNTER} ansible_host=${IP} ansible_user=ec2-user" >> ${INVENTORY_FILE}
  COUNTER=$((COUNTER + 1))
done

echo "" >> ${INVENTORY_FILE}
echo "[${ENVIRONMENT}_master]" >> ${INVENTORY_FILE}
echo "master ansible_host=${MASTER_PRIVATE_IP} ansible_user=ec2-user" >> ${INVENTORY_FILE}

echo "" >> ${INVENTORY_FILE}
echo "[${ENVIRONMENT}_admin]" >> ${INVENTORY_FILE}
echo "admin ansible_host=${ADMIN_PRIVATE_IP} ansible_user=ec2-user" >> ${INVENTORY_FILE}

echo "" >> ${INVENTORY_FILE}
echo "[${ENVIRONMENT}_worker]" >> ${INVENTORY_FILE}
COUNTER=1
for IP in $WORKER_PRIVATE_IPS; do
  echo "worker${COUNTER} ansible_host=${IP} ansible_user=ec2-user" >> ${INVENTORY_FILE}
  COUNTER=$((COUNTER + 1))
done

echo "Inventory for environment '${ENVIRONMENT}' generated at ${INVENTORY_FILE}"
#!/bin/bash

# Fetch the private IP of the master node
MASTER_PRIVATE_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=K8s-Master-DEV" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].PrivateIpAddress" --output text)

# Fetch the private IP of the admin node
ADMIN_PRIVATE_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=Admin-Server" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].PrivateIpAddress" --output text)

# Fetch the private IPs of the worker nodes
WORKER_PRIVATE_IPS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=K8s-Worker" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].PrivateIpAddress" --output text)



# Generate the inventory file
echo "[all]" > ${INVENTORY_DIR}
echo "master ansible_host=${MASTER_PRIVATE_IP} ansible_user=ec2-user" >> ${INVENTORY_DIR}
echo "admin ansible_host=${ADMIN_PRIVATE_IP} ansible_user=ec2-user" >> ${INVENTORY_DIR}
COUNTER=1
for IP in $WORKER_PRIVATE_IPS; do
  echo "worker${COUNTER} ansible_host=${IP} ansible_user=ec2-user" >> ${INVENTORY_DIR}
  COUNTER=$((COUNTER + 1))
done

echo "" >> ${INVENTORY_DIR}
echo "[master]" >> ${INVENTORY_DIR}
echo "master ansible_host=${MASTER_PRIVATE_IP} ansible_user=ec2-user" >> ${INVENTORY_DIR}

echo "" >> ${INVENTORY_DIR}
echo "[admin]" >> ${INVENTORY_DIR}
echo "admin ansible_host=${ADMIN_PRIVATE_IP} ansible_user=ec2-user" >> ${INVENTORY_DIR}

echo "" >> ${INVENTORY_DIR}
echo "[worker]" >> ${INVENTORY_DIR}
COUNTER=1
for IP in $WORKER_PRIVATE_IPS; do
  echo "worker${COUNTER} ansible_host=${IP} ansible_user=ec2-user" >> ${INVENTORY_DIR}
  COUNTER=$((COUNTER + 1))
done
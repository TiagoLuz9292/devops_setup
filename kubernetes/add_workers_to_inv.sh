#!/bin/bash
INVENTORY_PATH="/root/project/devops/kubernetes/inventory"

# Clear current workers from the inventory
sed -i '/\[workers\]/,/\[admin\]/d' $INVENTORY_PATH

# Add workers to the inventory
echo "[workers]" >> $INVENTORY_PATH
WORKER_IPS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=K8s-Worker" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].PublicIpAddress" --output text)
for IP in $WORKER_IPS; do
  echo "worker ansible_host=$IP ansible_user=ec2-user" >> $INVENTORY_PATH
done
echo "" >> $INVENTORY_PATH
echo "[admin]" >> $INVENTORY_PATH
echo "admin ansible_host=${aws_eip.admin_eip.public_ip} ansible_user=ec2-user" >> $INVENTORY_PATH
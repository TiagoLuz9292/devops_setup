#!/bin/bash


# Extract master private IP from inventory
MASTER_PRIVATE_IP=$(grep -A1 "\[master\]" $INVENTORY_DIR | tail -n1 | awk '{print $2}' | cut -d'=' -f2)

# Check if the IP was extracted successfully
if [ -z "$MASTER_PRIVATE_IP" ]; then
  echo "Failed to extract master private IP from inventory."
  exit 1
fi

# Run the Ansible playbook with the extracted private IP
ansible-playbook -i $INVENTORY_DIR $K8S_PLAYBOOK_DIR/setup_kubectl_auth.yaml --extra-vars "master_private_ip=$MASTER_PRIVATE_IP"
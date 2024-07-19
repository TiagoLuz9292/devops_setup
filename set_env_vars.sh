#!/bin/bash

# Get the home directory of the current user
USER_HOME=$(eval echo ~${SUDO_USER:-$USER})

# Create the required directory structure
mkdir -p "$USER_HOME/infrastructure"

# Define the environment variable and its value
DEVOPS_DIR="$USER_HOME/infrastructure/devops_setup"
INVENTORY_DIR="$DEVOPS_DIR/kubernetes/inventory"
K8S_PLAYBOOK_DIR="$DEVOPS_DIR/ansible/playbooks/kubernetes"




# Check if the export command already exists in .bashrc
if ! grep -q "export DEVOPS_DIR=" "$USER_HOME/.bashrc"; then
    echo "export DEVOPS_DIR=\"$DEVOPS_DIR\"" >> "$USER_HOME/.bashrc"
fi

if ! grep -q "export INVENTORY_DIR=" "$USER_HOME/.bashrc"; then
    echo "export INVENTORY_DIR=\"$INVENTORY_DIR\"" >> "$USER_HOME/.bashrc"
fi

if ! grep -q "export K8S_PLAYBOOK_DIR=" "$USER_HOME/.bashrc"; then
    echo "export K8S_PLAYBOOK_DIR=\"$K8S_PLAYBOOK_DIR\"" >> "$USER_HOME/.bashrc"
fi

# Set the environment variables for the current session
export DEVOPS_DIR="$DEVOPS_DIR"
export INVENTORY_DIR="$INVENTORY_DIR"
export K8S_PLAYBOOK_DIR="$K8S_PLAYBOOK_DIR"

# Add command aliases
if ! grep -q "alias devops=" "$USER_HOME/.bashrc"; then
    echo "alias devops='cd /home/ec2-user/infrastructure/devops_setup'" >> "$USER_HOME/.bashrc"
fi

if ! grep -q "alias ans_k8s=" "$USER_HOME/.bashrc"; then
    echo "alias ans_k8s='cd \$K8S_PLAYBOOK_DIR'" >> "$USER_HOME/.bashrc"
fi

if ! grep -q "alias tf=" "$USER_HOME/.bashrc"; then
    echo "alias tf='cd \$DEVOPS_DIR/terraform'" >> "$USER_HOME/.bashrc"
fi

# Source the .bashrc to apply changes to the current session
source "$USER_HOME/.bashrc"

echo "Base Devops dir set to $DEVOPS_DIR and added to .bashrc"
echo "Inventory directory set to $INVENTORY_DIR and added to .bashrc"
echo "Kubernetes playbook directory set to $K8S_PLAYBOOK_DIR and added to .bashrc"
echo "Command aliases added to .bashrc"
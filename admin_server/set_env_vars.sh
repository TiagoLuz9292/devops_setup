#!/bin/bash

# Get the home directory of the current user
USER_HOME=$(eval echo ~${SUDO_USER:-$USER})

# Create the required directory structure
mkdir -p "$USER_HOME"

# Define the environment variable and its value
DEVOPS_DIR="$USER_HOME/devops_setup"
INVENTORY_DIR="$DEVOPS_DIR/ansible/inventory/inventory"
TERRAFORM_DIR="$DEVOPS_DIR/terraform"
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
    echo "alias devops='cd /home/ec2-user/devops_setup'" >> "$USER_HOME/.bashrc"
fi

if ! grep -q "alias ans_k8s=" "$USER_HOME/.bashrc"; then
    echo "alias ans_k8s='cd \$K8S_PLAYBOOK_DIR'" >> "$USER_HOME/.bashrc"
fi

if ! grep -q "alias tf=" "$USER_HOME/.bashrc"; then
    echo "alias tf='cd \$DEVOPS_DIR/terraform'" >> "$USER_HOME/.bashrc"
fi

if ! grep -q "alias pods=" "$USER_HOME/.bashrc"; then
    echo "alias pods='kubectl get pods -n'" >> "$USER_HOME/.bashrc"
fi

if ! grep -q "alias svc=" "$USER_HOME/.bashrc"; then
    echo "alias svc='kubectl get svc -n'" >> "$USER_HOME/.bashrc"
fi

if ! grep -q "alias nodes=" "$USER_HOME/.bashrc"; then
    echo "alias nodes='kubectl get nodes'" >> "$USER_HOME/.bashrc"
fi

if ! grep -q "alias gen-inv=" "$USER_HOME/.bashrc"; then
    echo "alias gen-inv='/home/ec2-user/devops_setup/ansible/inventory/generate_inventory.sh'" >> "$USER_HOME/.bashrc"
fi

if ! grep -q "alias get-inv=" "$USER_HOME/.bashrc"; then
    echo "alias get-inv='cat /home/ec2-user/devops_setup/ansible/inventory/inventory'" >> "$USER_HOME/.bashrc"
fi


# Source the .bashrc to apply changes to the current session
source "$USER_HOME/.bashrc"


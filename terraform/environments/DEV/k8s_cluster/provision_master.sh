#!/bin/bash
set -e

# Check if all parameters are provided
if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <environment> <master_ip> <private_key_path> <aws_region>"
  exit 1
fi

ENVIRONMENT=$1
MASTER_IP=$2
PRIVATE_KEY_PATH=$3
AWS_REGION=$4
PARAMETER_NAME="k8s-join-command"

# Ensure correct permissions for the private key
chmod 600 $PRIVATE_KEY_PATH
eval "$(ssh-agent -s)"
ssh-add $PRIVATE_KEY_PATH



# Add the master IP to known hosts to avoid SSH prompt
ssh-keygen -R $MASTER_IP -f ~/.ssh/known_hosts || true
ssh-keyscan -H $MASTER_IP >> ~/.ssh/known_hosts

# Test SSH connection
echo "Testing SSH connection to master..."
ssh -o StrictHostKeyChecking=no -i $PRIVATE_KEY_PATH ec2-user@$MASTER_IP "echo 'SSH connection successful'"

# Run the script on the admin server to execute the Ansible playbook
echo "Starting the Ansible Playbook for Kubernetes installation on master"
echo "private key path: $PRIVATE_KEY_PATH"
bash /home/ec2-user/devops_setup/ansible/playbooks/kubernetes/setup_kubernetes_cluster.sh $ENVIRONMENT $MASTER_IP $PRIVATE_KEY_PATH > terraform_provision_master.log 2>&1
if [ $? -ne 0 ]; then
  echo "Failed to run setup_kubernetes_cluster.sh. Check terraform_provision_master.log for details."
  exit 1
fi

# Run the Ansible playbook to configure kubectl authentication
echo "Starting the Ansible Playbook for kubectl authentication setup"
bash /home/ec2-user/devops_setup/ansible/playbooks/kubernetes/setup_kubectl_auth.sh $ENVIRONMENT $MASTER_IP $PRIVATE_KEY_PATH > kubeconfig_setup.log 2>&1
if [ $? -ne 0 ]; then
  echo "Failed to run setup_kubectl_auth.sh. Check kubeconfig_setup.log for details."
  exit 1
fi

# Retrieve the join command
JOIN_COMMAND=$(ssh -o StrictHostKeyChecking=no -i $PRIVATE_KEY_PATH ec2-user@$MASTER_IP "sudo kubeadm token create --print-join-command")

# Store the join command in SSM Parameter Store
aws ssm put-parameter --name $PARAMETER_NAME --value "$JOIN_COMMAND" --type "String" --overwrite --region $AWS_REGION

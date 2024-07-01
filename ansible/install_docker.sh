#!/bin/bash

export ANSIBLE_GROUP=Docker
export AWS_REGION=eu-north-1

# Run the Python script to generate the inventory file
python3 /root/project/devops/aws_ec2_inventory.py --group $ANSIBLE_GROUP --region $AWS_REGION --output /root/project/devops/ansible/inventory.ini

# Use the generated inventory file to run the Ansible playbook
ansible-playbook -i /root/project/devops/ansible/inventory.ini playbooks/install_docker.yml
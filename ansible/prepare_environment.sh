export ANSIBLE_GROUP=Docker
export AWS_REGION=eu-north-1
ansible-playbook -i ./aws_ec2_inventory.py playbooks/prepare_environment.yml
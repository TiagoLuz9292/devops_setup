export ANSIBLE_GROUP=Docker
ansible-playbook -i ./aws_ec2_inventory.py playbooks/install_docker.yml
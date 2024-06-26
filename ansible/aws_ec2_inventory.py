#!/usr/bin/env python3

import boto3
import json
import os

def get_instances(group):
    ec2 = boto3.resource('ec2')
    instances = ec2.instances.filter(
        Filters=[{'Name': 'instance-state-name', 'Values': ['running']}]
    )

    inventory = {
        group: {'hosts': [], 'vars': {}},
        '_meta': {'hostvars': {}}
    }

    for instance in instances:
        for tag in instance.tags:
            if tag['Key'] == 'Group' and tag['Value'] == group:
                inventory[group]['hosts'].append(instance.public_ip_address)
                inventory['_meta']['hostvars'][instance.public_ip_address] = {
                    'ansible_host': instance.public_ip_address,
                    'private_ip': instance.private_ip_address
                }

    return inventory

if __name__ == "__main__":
    group = os.getenv('ANSIBLE_GROUP', 'default_group')
    inventory = get_instances(group)
    print(json.dumps(inventory, indent=4))
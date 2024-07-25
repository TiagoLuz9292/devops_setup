import boto3
import argparse

def get_instances(group, region):
    ec2 = boto3.resource('ec2', region_name=region)
    instances = ec2.instances.filter(Filters=[{
        'Name': 'tag:Group',
        'Values': [group]
    }])
    hosts = []
    for instance in instances:
        if instance.state['Name'] == 'running':
            hosts.append(instance.public_ip_address)
    return hosts

def write_inventory(group, hosts, output_file):
    with open(output_file, 'w') as f:
        f.write(f'[{group}]\n')
        for host in hosts:
            f.write(f'{host}\n')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Generate Ansible dynamic inventory from AWS EC2 instances.')
    parser.add_argument('--group', type=str, required=True, help='Tag group to filter instances.')
    parser.add_argument('--region', type=str, required=True, help='AWS region.')
    parser.add_argument('--output', type=str, required=True, help='Output file path for the inventory.')
    args = parser.parse_args()

    hosts = get_instances(args.group, args.region)
    write_inventory(args.group, hosts, args.output)
    print(f"Inventory file generated at {args.output}")
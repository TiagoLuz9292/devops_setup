import boto3
import subprocess
import os

def lambda_handler(event, context):
    ec2_client = boto3.client('ec2')
    
    private_key_path = os.environ['PRIVATE_KEY_PATH']
    inventory_path = os.environ['INVENTORY_PATH']
    playbook_path = os.environ['PLAYBOOK_PATH']
    
    # Extract the instance ID from the event
    instance_id = event['detail']['EC2InstanceId']
    
    # Get the public IP of the instance
    response = ec2_client.describe_instances(InstanceIds=[instance_id])
    instance_ip = response['Reservations'][0]['Instances'][0]['PublicIpAddress']
    
    # Update Ansible inventory
    with open(inventory_path, 'a') as f:
        f.write(f'worker ansible_host={instance_ip} ansible_user=ec2-user\n')
    
    # Add the instance IP to known hosts
    subprocess.run(['ssh-keyscan', '-H', instance_ip], stdout=open(os.path.expanduser('~/.ssh/known_hosts'), 'a'))
    
    # Run the Ansible playbook
    subprocess.run(['ansible-playbook', playbook_path, '--private-key', private_key_path])

    return {
        'statusCode': 200,
        'body': f'Successfully configured instance {instance_id} with IP {instance_ip}'
    }

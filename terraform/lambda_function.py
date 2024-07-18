import boto3
import subprocess
import os
import logging

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Create a file handler
log_file_path = "/tmp/ansible_playbook.log"  # Change to a specific path if needed
handler = logging.FileHandler(log_file_path)
handler.setLevel(logging.INFO)

# Create a logging format
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
handler.setFormatter(formatter)

# Add the handlers to the logger
logger.addHandler(handler)

def lambda_handler(event, context):
    ec2_client = boto3.client('ec2')
    
    private_key_path = os.environ['PRIVATE_KEY_PATH']
    inventory_path = os.environ['INVENTORY_PATH']
    playbook_path = os.environ['PLAYBOOK_PATH']
    generate_inventory_script_path = os.environ['INVENTORY_SCRIPT_PATH']  # Add this to your environment variables
    
    # Extract the instance ID from the event
    instance_id = event['detail']['EC2InstanceId']
    
    logger.info(f"Received event for instance ID: {instance_id}")
    
    # Get the public IP of the instance
    response = ec2_client.describe_instances(InstanceIds=[instance_id])
    instance_ip = response['Reservations'][0]['Instances'][0]['PublicIpAddress']
    
    logger.info(f"Instance public IP: {instance_ip}")
    
    # Update Ansible inventory
    with open(inventory_path, 'a') as f:
        f.write(f'worker ansible_host={instance_ip} ansible_user=ec2-user\n')
        logger.info(f"Added instance IP to inventory: {instance_ip}")
    
    # Add the instance IP to known hosts
    result = subprocess.run(['ssh-keyscan', '-H', instance_ip], stdout=open(os.path.expanduser('~/.ssh/known_hosts'), 'a'))
    if result.returncode == 0:
        logger.info(f"Successfully added {instance_ip} to known hosts")
    else:
        logger.error(f"Failed to add {instance_ip} to known hosts")
    
    # Regenerate the inventory to include the new instance
    result = subprocess.run([generate_inventory_script_path])
    if result.returncode == 0:
        logger.info("Successfully regenerated the inventory")
    else:
        logger.error("Failed to regenerate the inventory")
        logger.error(result.stderr)

    # Run the Ansible playbook
    result = subprocess.run(['ansible-playbook', playbook_path, '--private-key', private_key_path, '--limit', instance_ip], capture_output=True, text=True)
    
    if result.returncode == 0:
        logger.info(f"Successfully ran Ansible playbook on {instance_ip}")
        logger.info(result.stdout)
    else:
        logger.error(f"Failed to run Ansible playbook on {instance_ip}")
        logger.error(result.stderr)

    return {
        'statusCode': 200,
        'body': f'Successfully configured instance {instance_id} with IP {instance_ip}, log file: {log_file_path}'
    }
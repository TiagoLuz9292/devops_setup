import json
import boto3
import subprocess
import os

def lambda_handler(event, context):
    os.environ['KUBECONFIG'] = '/var/task/kubeconfig.yaml'
    kubectl_path = os.path.join(os.getcwd(), 'kubectl')

    asg_client = boto3.client('autoscaling')
    message = json.loads(event['Records'][0]['Sns']['Message'])
    
    lifecycle_hook_name = message['LifecycleHookName']
    auto_scaling_group_name = message['AutoScalingGroupName']
    instance_id = message['EC2InstanceId']
    
    # Get the instance details
    ec2_client = boto3.client('ec2')
    response = ec2_client.describe_instances(InstanceIds=[instance_id])
    private_ip = response['Reservations'][0]['Instances'][0]['PrivateIpAddress']
    
    
    # Drain the Kubernetes node
    try:
        result = subprocess.run([kubectl_path, 'drain', private_ip, '--ignore-daemonsets', '--delete-local-data'], capture_output=True, text=True)
        if result.returncode != 0:
            raise Exception(result.stderr)
        
        # Complete the lifecycle action
        asg_client.complete_lifecycle_action(
            LifecycleHookName=lifecycle_hook_name,
            AutoScalingGroupName=auto_scaling_group_name,
            LifecycleActionResult='CONTINUE',
            InstanceId=instance_id
        )
    except Exception as e:
        print(f"Error draining node: {e}")
        # If there's an error, fail the lifecycle action
        asg_client.complete_lifecycle_action(
            LifecycleHookName=lifecycle_hook_name,
            AutoScalingGroupName=auto_scaling_group_name,
            LifecycleActionResult='ABANDON',
            InstanceId=instance_id
        )

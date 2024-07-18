#!/bin/bash

# Install AWS CLI and jq if not installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI not found, installing..."
    sudo apt-get update
    sudo apt-get install -y awscli
fi

if ! command -v jq &> /dev/null; then
    echo "jq not found, installing..."
    sudo apt-get install -y jq
fi

# SQS Queue URL
SQS_QUEUE_URL="https://sqs.eu-north-1.amazonaws.com/891377403327/autoscaling-sqs"

while true; do
    # Receive message from SQS
    message=$(aws sqs receive-message --queue-url $SQS_QUEUE_URL --max-number-of-messages 1 --wait-time-seconds 20)

    if [ ! -z "$message" ]; then
        # Extract instance ID from the message
        instance_id=$(echo $message | jq -r '.Messages[0].Body' | jq -r '.EC2InstanceId')

        if [ "$instance_id" != "null" ]; then
            # Get instance IP
            instance_ip=$(aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

            # Update Ansible inventory
            echo "worker ansible_host=$instance_ip ansible_user=ec2-user" >> /root/project/devops/kubernetes/inventory

            # Run the Ansible playbook
            log_file_path="/root/project/devops/terraform/ansible_playbook_$instance_id.log"
            ansible-playbook /root/project/devops/ansible/playbooks/kubernetes/setup_kubernetes_worker.yaml --private-key /root/.ssh/my-key-pair --limit $instance_ip > "$log_file_path" 2>&1

            # Check if the playbook ran successfully and output the result
            if [ $? -eq 0 ]; then
                echo "Ansible playbook ran successfully on instance $instance_id. Logs saved to $log_file_path"
            else
                echo "Failed to run Ansible playbook on instance $instance_id. Check logs in $log_file_path for details."
            fi

            # Delete the message from the queue
            receipt_handle=$(echo $message | jq -r '.Messages[0].ReceiptHandle')
            aws sqs delete-message --queue-url $SQS_QUEUE_URL --receipt-handle $receipt_handle
        fi
    fi
done
#!/bin/bash

MASTER_IP=$1
ADMIN_IP=$2
WORKER_IPS=$3

echo "[all]" > /root/project/devops/kubernetes/inventory
echo "master ansible_host=${MASTER_IP} ansible_user=ec2-user" >> /root/project/devops/kubernetes/inventory
echo "admin ansible_host=${ADMIN_IP} ansible_user=ec2-user" >> /root/project/devops/kubernetes/inventory
COUNTER=1
for IP in $WORKER_IPS; do
  echo "worker${COUNTER} ansible_host=${IP} ansible_user=ec2-user" >> /root/project/devops/kubernetes/inventory
  COUNTER=$((COUNTER + 1))
done

echo "" >> /root/project/devops/kubernetes/inventory
echo "[master]" >> /root/project/devops/kubernetes/inventory
echo "master ansible_host=${MASTER_IP} ansible_user=ec2-user" >> /root/project/devops/kubernetes/inventory

echo "" >> /root/project/devops/kubernetes/inventory
echo "[admin]" >> /root/project/devops/kubernetes/inventory
echo "admin ansible_host=${ADMIN_IP} ansible_user=ec2-user" >> /root/project/devops/kubernetes/inventory

echo "" >> /root/project/devops/kubernetes/inventory
echo "[worker]" >> /root/project/devops/kubernetes/inventory
COUNTER=1
for IP in $WORKER_IPS; do
  echo "worker${COUNTER} ansible_host=${IP} ansible_user=ec2-user" >> /root/project/devops/kubernetes/inventory
  COUNTER=$((COUNTER + 1))
done
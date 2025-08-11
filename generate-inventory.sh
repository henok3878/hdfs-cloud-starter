#!/bin/bash

# This script generate Ansible inventory from Terraform outputs

cd "$(dirname "$0")/providers/gcp/terraform"

# check if terraform state exists
if [ ! -f "terraform.tfstate" ]; then
    echo "Error: No terraform state found. Please run 'terraform apply' first."
    exit 1
fi

# get IPs from Terraform
MASTER_IP=$(terraform output -raw master_ip 2>/dev/null)
MASTER_PRIVATE_IP=$(terraform output -raw master_private_ip 2>/dev/null)
WORKER_IPS=$(terraform output -json worker_ips 2>/dev/null)
WORKER_PRIVATE_IPS=$(terraform output -json worker_private_ips 2>/dev/null)

if [ -z "$MASTER_IP" ] || [ -z "$WORKER_IPS" ]; then
    echo "Error: Could not get IPs from Terraform outputs"
    exit 1
fi

# parse worker IPs
WORKER_IP_1=$(echo $WORKER_IPS | jq -r '.[0]')
WORKER_IP_2=$(echo $WORKER_IPS | jq -r '.[1]')
WORKER_PRIVATE_IP_1=$(echo $WORKER_PRIVATE_IPS | jq -r '.[0]')
WORKER_PRIVATE_IP_2=$(echo $WORKER_PRIVATE_IPS | jq -r '.[1]')

# go to project root
cd ../../..

# generate dynamic inventory
cat > ansible/inventory.yml << EOF
all:
  vars:
    ansible_user: ubuntu
    ansible_ssh_private_key_file: ~/.ssh/id_rsa
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
    ansible_ssh_pipelining: true
    ansible_become_method: sudo
    hadoop_version: "3.3.6"
    java_version: "openjdk-8-jdk"
    hadoop_home: "/opt/hadoop"
    hadoop_user: "hadoop"
    hdfs_data_dir: "/opt/hadoop/data"
    hdfs_namenode_dir: "/opt/hadoop/namenode"
    hdfs_temp_dir: "/opt/hadoop/tmp"
    
  children:
    masters:
      hosts:
        hadoop-master:
          ansible_host: "$MASTER_IP"
          private_ip: "$MASTER_PRIVATE_IP"
          
    workers:
      hosts:
        hadoop-worker-1:
          ansible_host: "$WORKER_IP_1"
          private_ip: "$WORKER_PRIVATE_IP_1"
        hadoop-worker-2:
          ansible_host: "$WORKER_IP_2"
          private_ip: "$WORKER_PRIVATE_IP_2"
EOF

echo "Generated Ansible inventory with the following IPs:"
echo "Master: $MASTER_IP (private: $MASTER_PRIVATE_IP)"
echo "Worker 1: $WORKER_IP_1 (private: $WORKER_PRIVATE_IP_1)"
echo "Worker 2: $WORKER_IP_2 (private: $WORKER_PRIVATE_IP_2)"

#!/bin/bash

# this script integrates Terraform and Ansible for smooth HDFS cluster deployment

set -e

# colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # no color 

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists terraform; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    if ! command_exists ansible; then
        print_error "Ansible is not installed. Please install Ansible first."
        exit 1
    fi
    
    if ! command_exists gcloud; then
        print_error "Google Cloud CLI is not installed. Please install gcloud first."
        exit 1
    fi
    
    print_success "All prerequisites are installed!"
}

# deploy infra with Terraform
deploy_infrastructure() {
    print_status "Deploying infra with Terraform..."
    
    cd providers/gcp/terraform
    
    terraform init
    
    terraform plan -out=tfplan
    
    terraform apply tfplan
    
    MASTER_IP=$(terraform output -raw master_ip)
    WORKER_IPS=$(terraform output -json worker_ips | jq -r '.[]')
    
    print_success "Infra deployed successfully!"
    print_status "Master IP: $MASTER_IP"
    print_status "Worker IPs: $WORKER_IPS"
    
    # wait for instances to fully boot
    print_status "Waiting 3 minutes for instances to fully boot and SSH to be ready..."
    sleep 180
    
    cd ../../..
}

# update Ansible inventory using Terraform outputs
update_inventory() {
    print_status "Updating Ansible inventory with Terraform outputs..."
    
    ./generate-inventory.sh
    
    if [ $? -ne 0 ]; then
        print_error "Failed to generate inventory"
        exit 1
    fi
    
    print_success "Inventory updated with actual IPs!"
}

# deploy HDFS with Ansible
deploy_hdfs() {
    print_status "Deploying HDFS cluster with Ansible..."
    
    cd ansible
    
    # wait for instances to fully boot and SSH to be ready
    print_status "Waiting for instances to fully boot (90 seconds)..."
    sleep 90
    
    # test connectivity with retries
    print_status "Testing connectivity to instances..."
    local max_retries=6
    local retry_delay=30
    local success=false
    
    # get master IP for ping test
    cd ../providers/gcp/terraform
    MASTER_IP=$(terraform output -raw master_ip 2>/dev/null)
    cd ../../../ansible
    
    for ((i=1; i<=max_retries; i++)); do
        print_status "Connectivity attempt $i/$max_retries..."
        
        print_status "Testing SSH connectivity to instances..."
        if ansible all -i inventory.yml -m ping --timeout=60 -f 5; then
            success=true
            break
        else
            print_warning "SSH connection failed, retrying..."
        fi
        
        if [ $i -lt $max_retries ]; then
            print_warning "Connection failed, waiting $retry_delay seconds before retry $((i+1))..."
            sleep $retry_delay
        fi
    done
    
    if [ "$success" = false ]; then
        print_error "Cannot connect to instances after $max_retries attempts."
        print_error "Please check:"
        print_error "1. Firewall rules allow SSH from your IP"
        print_error "2. Instances are running: gcloud compute instances list"
        print_error "3. Try manual SSH: ssh -o ConnectTimeout=10 ubuntu@[INSTANCE_IP]"
        exit 1
    fi
    
    print_success "Successfully connected to all instances!"
    
    # run Ansible playbook
    print_status "Running HDFS installation playbook..."
    ansible-playbook -i inventory.yml hdfs-cluster.yml -v --timeout=300
    
    if [ $? -eq 0 ]; then
        print_success "HDFS cluster deployed successfully!"
    else
        print_error "HDFS deployment failed!"
        exit 1
    fi
    
    cd ..
}

# show cluster information
show_cluster_info() {
    print_success "=== HDFS Cluster Information ==="
    
    cd providers/gcp/terraform
    
    # get cluster info from Terraform outputs
    if [ -f "terraform.tfstate" ]; then
        CLUSTER_INFO=$(terraform output -json cluster_info 2>/dev/null)
        MASTER_IP=$(terraform output -raw master_ip 2>/dev/null)
        
        if [ ! -z "$CLUSTER_INFO" ] && [ ! -z "$MASTER_IP" ]; then
            echo -e "${GREEN}NameNode Web UI:${NC} $(echo $CLUSTER_INFO | jq -r '.namenode_web_ui')"
            echo -e "${GREEN}NameNode Admin UI:${NC} $(echo $CLUSTER_INFO | jq -r '.namenode_admin_ui')"
            echo -e "${GREEN}SSH to Master:${NC} $(echo $CLUSTER_INFO | jq -r '.master_ssh')"
        else
            echo -e "${RED}Error: Could not retrieve cluster information${NC}"
        fi
    else
        echo -e "${RED}Error: No terraform state found${NC}"
    fi
    
    cd ../../..
    
    echo ""
    echo -e "${YELLOW}Useful HDFS Commands:${NC}"
    echo "  hdfs dfs -ls /"
    echo "  hdfs dfs -mkdir /test"
    echo "  hdfs dfs -put localfile /test/"
    echo "  hdfs dfsadmin -report"
    echo ""
    echo -e "${YELLOW}To test HDFS:${NC}"
    echo "  ssh ubuntu@$MASTER_IP"
    echo "  sudo su - hadoop"
    echo "  hdfs dfs -ls /"
}

# cleanup function
cleanup() {
    print_status "Cleaning up resources..."
    
    cd providers/gcp/terraform
    terraform destroy -auto-approve
    cd ../../..
    
    print_success "All resources cleaned up!"
}

# main function
main() {
    case "${1:-}" in
        "deploy")
            check_prerequisites
            deploy_infrastructure
            update_inventory
            deploy_hdfs
            show_cluster_info
            ;;
        "destroy")
            cleanup
            ;;
        "info")
            show_cluster_info
            ;;
        *)
            echo "HDFS Cloud Starter"
            echo ""
            echo "Usage: $0 {deploy|destroy|info}"
            echo ""
            echo "Commands:"
            echo "  deploy   - Deploy complete HDFS cluster"
            echo "  destroy  - Destroy all resources"
            echo "  info     - Show cluster information"
            echo ""
            exit 1
            ;;
    esac
}

main "$@"

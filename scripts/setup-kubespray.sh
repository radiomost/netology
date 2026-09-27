#!/bin/bash

# Script to automate Kubespray setup and inventory generation
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Kubespray Setup Script ===${NC}"

# Check if we're in the right directory
if [ ! -d "stage2-compute" ]; then
    echo -e "${RED}Error: stage2-compute directory not found. Please run from project root.${NC}"
    exit 1
fi

# Step 1: Clone Kubespray if not exists
if [ ! -d "kubespray" ]; then
    echo -e "${YELLOW}Cloning Kubespray repository...${NC}"
    git clone https://github.com/kubernetes-sigs/kubespray.git
else
    echo -e "${GREEN}Kubespray already cloned.${NC}"
fi

cd kubespray

# Step 2: Setup Python environment with pyenv
echo -e "${YELLOW}Setting up Python environment...${NC}"

if ! command -v pyenv &> /dev/null; then
    echo -e "${RED}Error: pyenv is not installed. Please install pyenv first.${NC}"
    exit 1
fi

if ! pyenv versions | grep -q "3.12.10"; then
    echo -e "${RED}Error: Python 3.12.10 is not installed in pyenv. Install it with: pyenv install 3.12.10${NC}"
    exit 1
fi

if ! pyenv versions | grep -q "netology"; then
    echo -e "${YELLOW}Creating pyenv virtualenv 'netology' with Python 3.12.10...${NC}"
    pyenv virtualenv 3.12.10 netology
else
    echo -e "${GREEN}Virtualenv 'netology' already exists.${NC}"
fi

pyenv local netology

echo -e "${YELLOW}Installing Python dependencies...${NC}"
pip install -r requirements.txt

# Step 3: Copy sample inventory
echo -e "${YELLOW}Setting up inventory directory...${NC}"
if [ ! -d "inventory/mycluster" ]; then
    cp -rfp inventory/sample inventory/mycluster
    echo -e "${GREEN}Inventory template copied.${NC}"
else
    echo -e "${GREEN}Inventory directory already exists.${NC}"
fi

# Step 4: Get IPs from Terraform output
echo -e "${YELLOW}Fetching IP addresses from Terraform...${NC}"
cd ../stage2-compute

# Initialize terraform if needed (to read state from S3 backend)
if [ ! -d ".terraform" ]; then
    echo -e "${YELLOW}Initializing Terraform in stage2-compute...${NC}"
    terraform init -input=false
fi

# Extract IPs from terraform output
MASTER_IP=$(terraform output -raw master_external_ip 2>/dev/null || echo "")
WORKER1_IP=$(terraform output -json workers_external_ips 2>/dev/null | jq -r '."worker-1"' || echo "")
WORKER2_IP=$(terraform output -json workers_external_ips 2>/dev/null | jq -r '."worker-2"' || echo "")

MASTER_INT_IP=$(terraform output -raw master_internal_ip 2>/dev/null || echo "")
WORKER1_INT_IP=$(terraform output -json workers_internal_ips 2>/dev/null | jq -r '."worker-1"' || echo "")
WORKER2_INT_IP=$(terraform output -json workers_internal_ips 2>/dev/null | jq -r '."worker-2"' || echo "")

if [ -z "$MASTER_IP" ] || [ -z "$WORKER1_IP" ] || [ -z "$WORKER2_IP" ]; then
    echo -e "${RED}Error: Could not fetch external IP addresses from Terraform output.${NC}"
    echo "Make sure VMs are created with 'terraform apply' in stage2-compute."
    exit 1
fi

if [ -z "$MASTER_INT_IP" ] || [ -z "$WORKER1_INT_IP" ] || [ -z "$WORKER2_INT_IP" ]; then
    echo -e "${RED}Error: Could not fetch internal IP addresses from Terraform output.${NC}"
    exit 1
fi

echo -e "${GREEN}Found IPs:${NC}"
echo "  Master:   $MASTER_IP (internal: $MASTER_INT_IP)"
echo "  Worker-1: $WORKER1_IP (internal: $WORKER1_INT_IP)"
echo "  Worker-2: $WORKER2_IP (internal: $WORKER2_INT_IP)"

# Step 5: Generate inventory directly
cd ../kubespray
echo -e "${YELLOW}Generating Ansible inventory (hosts.yaml)...${NC}"

cat > inventory/mycluster/hosts.yaml <<EOF
all:
  hosts:
    node1:
      ansible_host: ${MASTER_IP}
      ip: ${MASTER_INT_IP}
      access_ip: ${MASTER_INT_IP}
    node2:
      ansible_host: ${WORKER1_IP}
      ip: ${WORKER1_INT_IP}
      access_ip: ${WORKER1_INT_IP}
    node3:
      ansible_host: ${WORKER2_IP}
      ip: ${WORKER2_INT_IP}
      access_ip: ${WORKER2_INT_IP}
  children:
    kube_control_plane:
      hosts:
        node1: {}
    kube_node:
      hosts:
        node2: {}
        node3: {}
    etcd:
      hosts:
        node1: {}
    k8s_cluster:
      children:
        kube_control_plane: {}
        kube_node: {}
    calico_rr:
      hosts: {}
EOF

echo -e "${GREEN}=== Kubespray setup complete! ===${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review inventory: cat kubespray/inventory/mycluster/hosts.yaml"
echo "  2. Deploy cluster: make kubespray-deploy"
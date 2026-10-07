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

# Step 1: Clone Kubespray and PIN TO A SPECIFIC STABLE VERSION
if [ ! -d "kubespray" ]; then
    echo -e "${YELLOW}Cloning Kubespray repository...${NC}"
    git clone https://github.com/kubernetes-sigs/kubespray.git
    echo -e "${YELLOW}Checking out stable release v2.25.0...${NC}"
    cd kubespray
    git checkout v2.25.0
    cd ..
else
    echo -e "${GREEN}Kubespray directory exists. Ensuring correct version...${NC}"
    cd kubespray
    git checkout v2.25.0
    cd ..
fi

cd kubespray

# Step 2: Setup Python environment
echo -e "${YELLOW}Setting up Python environment...${NC}"

if [ -n "$CI" ]; then
    echo -e "${GREEN}Detected GitLab CI environment. Using system Python3 and standard venv.${NC}"
    python3 -m venv venv
    source venv/bin/activate
    pip3 install --upgrade pip
else
    echo -e "${YELLOW}Local environment detected. Using pyenv.${NC}"
    if ! command -v pyenv &> /dev/null; then
        echo -e "${RED}Error: pyenv is not installed. Please install pyenv first.${NC}"
        exit 1
    fi
    
    eval "$(pyenv init -)"
    
    if ! pyenv versions --bare | grep -q "3.12.10"; then
        echo -e "${RED}Error: Python 3.12.10 is not installed in pyenv. Install it with: pyenv install 3.12.10${NC}"
        exit 1
    fi

    if ! pyenv virtualenvs --bare | grep -q "netology"; then
        echo -e "${YELLOW}Creating pyenv virtualenv 'netology' with Python 3.12.10...${NC}"
        pyenv virtualenv 3.12.10 netology
    else
        echo -e "${GREEN}Virtualenv 'netology' already exists.${NC}"
    fi

    pyenv local netology
fi

echo -e "${YELLOW}Installing Python dependencies...${NC}"
pip install -r requirements.txt

# ... (далее ваш скрипт остается без изменений до конца) ...
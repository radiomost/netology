#!/bin/bash

# Script to setup Python virtual environment (fallback when pyenv is not available)
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Setting up Python virtual environment ===${NC}"

# Check if python3 is available
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: python3 is not installed. Please install Python 3.10 or higher.${NC}"
    exit 1
fi

# Get Python version
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
echo -e "${YELLOW}Found Python version: ${PYTHON_VERSION}${NC}"

# Check if we're in kubespray directory
if [ ! -f "requirements.txt" ]; then
    echo -e "${RED}Error: requirements.txt not found. Please run this script from kubespray directory.${NC}"
    exit 1
fi

# Create virtual environment
VENV_DIR="venv"
if [ ! -d "$VENV_DIR" ]; then
    echo -e "${YELLOW}Creating virtual environment in ${VENV_DIR}...${NC}"
    python3 -m venv $VENV_DIR
    echo -e "${GREEN}✓ Virtual environment created.${NC}"
else
    echo -e "${GREEN}✓ Virtual environment already exists.${NC}"
fi

# Activate virtual environment
echo -e "${YELLOW}Activating virtual environment...${NC}"
source $VENV_DIR/bin/activate

# Upgrade pip
echo -e "${YELLOW}Upgrading pip...${NC}"
pip install --upgrade pip

# Install requirements
echo -e "${YELLOW}Installing Python dependencies from requirements.txt...${NC}"
pip install -r requirements.txt

echo -e "${GREEN}=== Python virtual environment setup complete! ===${NC}"
echo -e "${YELLOW}To activate manually, run: source ${VENV_DIR}/bin/activate${NC}"
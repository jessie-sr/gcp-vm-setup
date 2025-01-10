#!/bin/bash

# Check if required arguments are provided
# Usage: ./setup.sh <USERNAME> <EXTERNAL_IP> <CODE_SERVER_PW> <EMAIL_ADDR>
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <CODE_SERVER_PW>"
    exit 1
fi

# Assign script arguments to variables for better readability
CODE_SERVER_PW=$1   # Password to log in to code-server

echo "Using CODE_SERVER_PW=$CODE_SERVER_PW"

# Update and upgrade system packages to ensure the system is up-to-date
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker to run containerized applications like Jupyter Notebook
echo "Installing Docker..."
sudo apt install -y docker.io

# Add the current user to the Docker group to allow non-root access to Docker
echo "Configuring Docker permissions..."
sudo usermod -aG docker $USER
echo "Docker group changes applied. Logging in this session to apply permissions..."
newgrp docker <<EOF

# Start a subshell where Docker permissions are applied

# Install Node.js and npm, required for installing code-server
echo "Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install code-server, a web-based VS Code implementation
echo "Installing code-server..."
curl -fsSL https://code-server.dev/install.sh | sh

# Start code-server with the provided password and bind it to port 8080
echo "Starting code-server..."
PASSWORD=$CODE_SERVER_PW code-server --bind-addr=0.0.0.0:8080 &

# Deploy Jupyter Notebook using Docker
echo "Setting up Jupyter Notebook..."
docker run -d \
    --name jupyter-notebook \
    -p 8888:8888 \
    -v ~/jupyter-data:/home/jovyan/work \
    jupyter/base-notebook

EOF

# Install and configure UFW (Uncomplicated Firewall) to allow only SSH traffic
echo "Configuring firewall..."
sudo apt install -y ufw
sudo ufw allow ssh
sudo ufw enable


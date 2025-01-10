#!/bin/bash

# Check if required arguments are provided
# Usage: ./setup.sh <USERNAME> <EXTERNAL_IP> <CODE_SERVER_PW> <EMAIL_ADDR>
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <USERNAME> <EXTERNAL_IP> <CODE_SERVER_PW> <EMAIL_ADDR>"
    exit 1
fi

# Assign script arguments to variables for better readability
USERNAME=$1         # The username for SSH access to the remote server
EXTERNAL_IP=$2      # The external IP of the remote server
CODE_SERVER_PW=$3   # Password to log in to code-server
EMAIL_ADDR=$4       # Email address used for generating the SSH key

echo "Using USERNAME=$USERNAME, EXTERNAL_IP=$EXTERNAL_IP, CODE_SERVER_PW=$CODE_SERVER_PW, EMAIL_ADDR=$EMAIL_ADDR"

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

# Check if SSH key exists; generate one if not
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "Generating SSH key..."
    ssh-keygen -t rsa -b 4096 -C "$EMAIL_ADDR" -N "" -f ~/.ssh/id_rsa
fi

# Add public key to the remote server manually
echo "Manually adding SSH public key to the remote server..."
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
mkdir -p ~/.ssh && chmod 700 ~/.ssh
echo $SSH_KEY >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Set up an SSH tunnel to forward local port 8080 to remote port 8080 for code-server
# Set up an SSH tunnel to forward local port 8888 to remote port 8888 for Jupyter Notebook
echo "Setting up SSH Tunnel for code-server and Jupyter Notebook..."
ssh -L 0.0.0.0:8080:localhost:8081 -L 0.0.0.0:8888:localhost:8889 $USERNAME@$EXTERNAL_IP -N

echo "Setup complete! You can access code-server at http://localhost:8080 and Jupyter Notebook at http://localhost:8888."
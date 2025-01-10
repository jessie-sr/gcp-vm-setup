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

echo "Using USERNAME=$USERNAME, EXTERNAL_IP=$EXTERNAL_IP"

# Update and upgrade system packages to ensure the system is up-to-date
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker to run containerized applications like Jupyter Notebook
echo "Installing Docker..."
sudo apt install -y docker.io

echo "Configuring Docker permissions..."
sudo usermod -aG docker $USER
echo "Please log out and back in to apply Docker group changes or run 'newgrp docker' in this session."

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
# Maps port 8888 on the host to port 8888 in the container
# Mounts ~/jupyter-data to /home/jovyan/work inside the container for persistent storage
echo "Setting up Jupyter Notebook..."
docker run -d \
    --name jupyter-notebook \
    -p 8888:8888 \
    -v ~/jupyter-data:/home/jovyan/work \
    jupyter/base-notebook

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

# Copy the public SSH key to the remote server for passwordless authentication
echo "Adding SSH public key to the remote server..."
ssh-copy-id -i ~/.ssh/id_rsa.pub $USERNAME@$EXTERNAL_IP

# Set up an SSH tunnel to forward local port 8080 to remote port 8080 for code-server
echo "Setting up SSH Tunnel for code-server..."
ssh -L 8080:localhost:8080 $USERNAME@$EXTERNAL_IP -N &

# Set up an SSH tunnel to forward local port 8888 to remote port 8888 for Jupyter Notebook
echo "Setting up SSH Tunnel for Jupyter Notebook..."
ssh -L 8888:localhost:8888 $USERNAME@$EXTERNAL_IP -N &

echo "Setup complete! You can access code-server at http://localhost:8080 and Jupyter Notebook at http://localhost:8888."
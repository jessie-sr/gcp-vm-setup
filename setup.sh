#!/bin/bash

# Update system packages
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker
echo "Installing Docker..."
sudo apt install -y docker.io

# Allow Docker to run without sudo
echo "Configuring Docker..."
sudo usermod -aG docker $USER
newgrp docker

# Install Node.js and npm (for code-server)
echo "Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install code-server
echo "Installing code-server..."
curl -fsSL https://code-server.dev/install.sh | sh

# Start code-server
echo "Starting code-server..."
PASSWORD="code-server-password" code-server --bind-addr=0.0.0.0:8080 & # Replace "code-server-password" with your own code server password

# Set up Jupyter Notebook with Docker
echo "Setting up Jupyter Notebook..."
docker run -d \
    --name jupyter-notebook \
    -p 8888:8888 \
    -v ~/jupyter-data:/home/jovyan/work \
    jupyter/base-notebook

# Configure firewall with ufw
echo "Configuring firewall..."
sudo apt install -y ufw
sudo ufw allow ssh
sudo ufw enable

# Generate SSH key if not exists
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "Generating SSH key..."
    ssh-keygen -t rsa -b 4096 -C "your_email@example.com" -N "" -f ~/.ssh/id_rsa # Replace "your_email@example.com" with your email address
fi

# Add public key to remote server
echo "Adding SSH public key to the VM..."
ssh-copy-id -i ~/.ssh/id_rsa.pub <USERNAME>@<EXTERNAL_IP> # Replace <USERNAME> and <EXTERNAL_IP> with your VM username and external IP

# Set up SSH Tunnel for code-server
echo "Setting Up SSH Tunnel for code-server..."
ssh -L 8080:localhost:8080 <USERNAME>@<EXTERNAL_IP> -N & # Replace <USERNAME> and <EXTERNAL_IP> with your own username and VM external IP

# Set up SSH Tunnel for Jupyter Notebook
echo "Setting Up SSH Tunnel for Jupyter Notebook..."
ssh -L 8888:localhost:8888 <USERNAME>@<EXTERNAL_IP> -N &

echo "Setup complete!"
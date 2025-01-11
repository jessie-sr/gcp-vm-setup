#!/bin/bash

# Check if required arguments are provided
# Usage: ./setup.sh <USERNAME> <EXTERNAL_IP> <CODE_SERVER_PW> <EMAIL_ADDR>
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <USERNAME> <EXTERNAL_IP> <EMAIL_ADDR>"
    exit 1
fi

# Assign script arguments to variables for better readability
USERNAME=$1         # The username for SSH access to the remote server
EXTERNAL_IP=$2      # The external IP of the remote server
EMAIL_ADDR=$3       # Email address used for generating the SSH key

echo "Using USERNAME=$USERNAME, EXTERNAL_IP=$EXTERNAL_IP, EMAIL_ADDR=$EMAIL_ADDR"

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
ssh -L 0.0.0.0:8081:localhost:8080 -L 0.0.0.0:8889:localhost:8888 $USERNAME@$EXTERNAL_IP -N &

echo "Setup complete! You can access code-server at http://localhost:8081 and Jupyter Notebook at http://localhost:8889/labs."
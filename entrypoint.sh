#!/bin/bash
set -e

# Set the SSH password for the 'claude' user from the environment variable
# This is injected by docker-compose from the .env file
if [ -z "$SSH_PASSWORD" ]; then
    echo "ERROR: SSH_PASSWORD environment variable is not set."
    exit 1
fi

echo "claude:${SSH_PASSWORD}" | chpasswd

# Regenerate host keys if they don't exist (first boot)
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -A
fi

echo "SSH server starting on port 22..."
exec /usr/sbin/sshd -D

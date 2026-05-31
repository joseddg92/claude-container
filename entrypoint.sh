#!/bin/bash
set -e

# Install the public key from the bind-mounted file into authorized_keys.
# The key file is mounted read-only at /run/secrets/authorized_keys via
# docker-compose, so we copy it into the right place with correct ownership.
AUTHORIZED_KEYS_SRC="/run/secrets/authorized_keys"
AUTHORIZED_KEYS_DEST="/home/claude/.ssh/authorized_keys"

if [ ! -f "$AUTHORIZED_KEYS_SRC" ]; then
    echo "ERROR: No authorized_keys file found at $AUTHORIZED_KEYS_SRC"
    echo "Mount your public key file in docker-compose.yml under secrets."
    exit 1
fi

cp "$AUTHORIZED_KEYS_SRC" "$AUTHORIZED_KEYS_DEST"
chmod 600 "$AUTHORIZED_KEYS_DEST"
chown claude:claude "$AUTHORIZED_KEYS_DEST"

# Regenerate host keys if they don't exist (first boot)
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -A
fi

echo "SSH server starting (key-only auth)..."
exec /usr/sbin/sshd -D

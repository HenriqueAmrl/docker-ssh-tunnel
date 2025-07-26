#!/bin/sh
# create an ssh tunnel to a bastion host, then tunnel into db from there

# required variables
# LOCAL_PORT=3312
# REMOTE_PORT=3306
# REMOTE_SERVER_IP="my.internal.mariadb.server" # defaults to 127.0.0.1
# SSH_BASTION_HOST="bastion.host"
# SSH_PORT=22 # defaults to 22
# SSH_USER="tunnel_user"
# SSH_KEY_PATH="/ssh_key/id_rsa" # defaults to /ssh_key/id_rsa

# Function to read variable from file if _FILE version exists
read_var_from_file() {
    local var_name=$1
    local file_var_name="${var_name}_FILE"
    local file_path=""
    
    # Get the file path using eval to avoid indirect expansion
    eval "file_path=\$$file_var_name"
    
    if [ -n "$file_path" ]; then
        if [ -f "$file_path" ]; then
            local value=$(cat "$file_path" | tr -d '[:space:]')
            eval "$var_name=\"$value\""
        else
            echo "File not found: $file_path"
            exit 1
        fi
    fi
}

# Function to setup SSH key with proper permissions
setup_ssh_key() {
    local key_path="$1"
    local temp_key_path=""
    
    # If key is from /run/secrets, copy it to ~/.ssh/ directory
    if echo "$key_path" | grep -q "^/run/secrets/"; then
        # Ensure ~/.ssh directory exists with proper permissions
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        
        temp_key_path="$HOME/.ssh/ssh_key_$$"
        cp "$key_path" "$temp_key_path"
        chmod 600 "$temp_key_path"
        
        # Verify permissions are correct for SSH
        if [ "$(stat -c %a "$temp_key_path" 2>/dev/null || stat -f %Lp "$temp_key_path" 2>/dev/null)" != "600" ]; then
            echo "Warning: SSH key permissions may not be secure"
        fi
        
        echo "$temp_key_path"
    else
        # For regular paths, just set permissions
        chmod 600 "$key_path"
        echo "$key_path"
    fi
}

# Read variables from files if _FILE versions exist
read_var_from_file "LOCAL_PORT"
read_var_from_file "REMOTE_PORT"
read_var_from_file "REMOTE_SERVER_IP"
read_var_from_file "SSH_BASTION_HOST"
read_var_from_file "SSH_PORT"
read_var_from_file "SSH_USER"
read_var_from_file "SSH_KEY_PATH"

if [ -z ${REMOTE_SERVER_IP+x} ]; then
    REMOTE_SERVER_IP="127.0.0.1"
fi

if  [ -z ${SSH_PORT+x} ] ; then
    SSH_PORT="22"
fi

if [ -z ${SSH_KEY_PATH+x} ]; then
    SSH_KEY_PATH="/ssh_key/id_rsa"
fi

if [ -z ${LOCAL_PORT+x} ] || [ -z ${REMOTE_PORT+x} ] || [ -z ${SSH_BASTION_HOST+x} ] || [ -z ${SSH_USER+x} ] ; then 
    echo "some vars are not set"; 
    exit 1
fi

# Check if SSH key file exists
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "SSH key file not found at: $SSH_KEY_PATH"
    exit 1
fi

# Setup SSH key with proper permissions
ACTUAL_SSH_KEY_PATH=$(setup_ssh_key "$SSH_KEY_PATH")

echo "starting SSH proxy $LOCAL_PORT:$REMOTE_SERVER_IP:$REMOTE_PORT on $SSH_USER@$SSH_BASTION_HOST:$SSH_PORT using key: $ACTUAL_SSH_KEY_PATH"

# Cleanup function for temporary files
cleanup() {
    if [ -n "$ACTUAL_SSH_KEY_PATH" ] && [ "$ACTUAL_SSH_KEY_PATH" != "$SSH_KEY_PATH" ]; then
        rm -f "$ACTUAL_SSH_KEY_PATH"
    fi
}

# Set trap to cleanup on exit
trap cleanup EXIT

/usr/bin/ssh \
-NTC -o ServerAliveInterval=60 \
-o GatewayPorts=true \
-o ExitOnForwardFailure=yes \
-o StrictHostKeyChecking=no \
-L $LOCAL_PORT:$REMOTE_SERVER_IP:$REMOTE_PORT \
$SSH_USER@$SSH_BASTION_HOST \
-p $SSH_PORT \
-i "$ACTUAL_SSH_KEY_PATH"

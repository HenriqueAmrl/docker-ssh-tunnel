#!/bin/sh
# create an ssh tunnel to a bastion host, then tunnel into db from there

# required variables
# LOCAL_PORT=3312
# REMOTE_PORT=3306
# REMOTE_SERVER_IP="my.internal.mariadb.server" # defaults to 127.0.0.1
# SSH_BASTION_HOST="bastion.host"
# SSH_PORT=22 # defaults to 22
# SSH_USER="tunnel_user"
# SSH_KEY="-----BEGIN OPENSSH PRIVATE KEY-----\n..." # direct key content

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

# Function to setup SSH key from SSH_KEY content
setup_ssh_key() {
    local key_content=""
    
    # SSH_KEY should already be set (either directly or via read_var_from_file from SSH_KEY_FILE)
    if [ -z "${SSH_KEY+x}" ]; then
        echo "SSH_KEY or SSH_KEY_FILE must be set" >&2
        return 1
    fi
    
    key_content="$SSH_KEY"
    
    # Ensure HOME is set (default to /root if not set, common in containers)
    if [ -z "$HOME" ]; then
        HOME="/root"
    fi
    
    # Ensure ~/.ssh directory exists with proper permissions
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    
    # Create temporary key file
    local temp_key_path="$HOME/.ssh/ssh_key_$$"
    echo "$key_content" > "$temp_key_path"
    chmod 600 "$temp_key_path"
    
    # Verify permissions are correct for SSH
    if [ "$(stat -c %a "$temp_key_path" 2>/dev/null || stat -f %Lp "$temp_key_path" 2>/dev/null)" != "600" ]; then
        echo "Warning: SSH key permissions may not be secure" >&2
    fi
    
    echo "$temp_key_path"
    return 0
}

# Read variables from files if _FILE versions exist
read_var_from_file "LOCAL_PORT"
read_var_from_file "REMOTE_PORT"
read_var_from_file "REMOTE_SERVER_IP"
read_var_from_file "SSH_BASTION_HOST"
read_var_from_file "SSH_PORT"
read_var_from_file "SSH_USER"
read_var_from_file "SSH_KEY"

if [ -z ${REMOTE_SERVER_IP+x} ]; then
    REMOTE_SERVER_IP="127.0.0.1"
fi

if  [ -z ${SSH_PORT+x} ] ; then
    SSH_PORT="22"
fi

if [ -z ${LOCAL_PORT+x} ] || [ -z ${REMOTE_PORT+x} ] || [ -z ${SSH_BASTION_HOST+x} ] || [ -z ${SSH_USER+x} ] ; then 
    echo "some vars are not set"; 
    exit 1
fi

# Setup SSH key from SSH_KEY (which may have been set via SSH_KEY_FILE by read_var_from_file)
ACTUAL_SSH_KEY_PATH=$(setup_ssh_key 2>/tmp/ssh_key_error_$$)
KEY_SETUP_EXIT_CODE=$?
if [ $KEY_SETUP_EXIT_CODE -ne 0 ] || [ -z "$ACTUAL_SSH_KEY_PATH" ]; then
    if [ -f /tmp/ssh_key_error_$$ ]; then
        cat /tmp/ssh_key_error_$$ >&2
        rm -f /tmp/ssh_key_error_$$
    fi
    exit 1
fi
rm -f /tmp/ssh_key_error_$$
USE_TEMP_KEY=true

echo "starting SSH proxy $LOCAL_PORT:$REMOTE_SERVER_IP:$REMOTE_PORT on $SSH_USER@$SSH_BASTION_HOST:$SSH_PORT using key: $ACTUAL_SSH_KEY_PATH"

# Cleanup function for temporary files
cleanup() {
    if [ "$USE_TEMP_KEY" = true ] && [ -n "$ACTUAL_SSH_KEY_PATH" ]; then
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

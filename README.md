# Docker SSH Tunnel

Create a lightweight Alpine Linux based SSH tunnel to a host.  Uses pure SSH, no fluff.

## Versions

[![dockeri.co](http://dockeri.co/image/henriqueamrl/docker-ssh-tunnel)](https://hub.docker.com/r/henriqueamrl/docker-ssh-tunnel/)

- [`v1.9`,  `latest` (*Dockerfile*)](https://github.com/henriqueamrl/docker-ssh-tunnel/blob/v1.9/Dockerfile) [![](https://images.microbdger.com/badges/image/henriqueamrl/docker-ssh-tunnel.svg)](http://microbadger.com/images/henriqueamrl/docker-ssh-tunnel "Get your own image badge on microbadger.com")
- [`v1.8`, `v1.8.2`, (*Dockerfile*)](https://github.com/henriqueamrl/docker-ssh-tunnel/blob/v1.8.2/Dockerfile) [![](https://images.microbdger.com/badges/image/henriqueamrl/docker-ssh-tunnel.svg)](http://microbadger.com/images/henriqueamrl/docker-ssh-tunnel "Get your own image badge on microbadger.com")
- [`v1.7`, `v1.7.2` (*Dockerfile*)](https://github.com/henriqueamrl/docker-ssh-tunnel/blob/v1.7/Dockerfile) [![](https://images.microbdger.com/images/henriqueamrl/docker-ssh-tunnel "Get your own image badge on microbadger.com")
- [`v1.6` (*Dockerfile*)](https://github.com/henriqueamrl/docker-ssh-tunnel/blob/v1.6/Dockerfile) [![](https://images.microbdger.com/badges/image/henriqueamrl/docker-ssh-tunnel.svg)](http://microbadger.com/images/henriqueamrl/docker-ssh-tunnel "Get your own image badge on microbadger.com")
- [`v1.5` (*Dockerfile*)](https://github.com/henriqueamrl/docker-ssh-tunnel/blob/v1.5/Dockerfile) [![](https://images.microbdger.com/badges/image/henriqueamrl/docker-ssh-tunnel.svg)](http://microbadger.com/images/henriqueamrl/docker-ssh-tunnel "Get your own image badge on microbadger.com")
- [`v1.4` (*Dockerfile*)](https://github.com/henriqueamrl/docker-ssh-tunnel/blob/v1.4/Dockerfile) [![](https://images.microbdger.com/badges/image/henriqueamrl/docker-ssh-tunnel.svg)](http://microbadger.com/images/henriqueamrl/docker-ssh-tunnel "Get your own image badge on microbadger.com")
- [`v1.3`, `v1.3.1` (*Dockerfile*)](https://github.com/henriqueamrl/docker-ssh-tunnel/blob/v1.3.1/Dockerfile) [![](https://images.microbdger.com/badges/image/henriqueamrl/docker-ssh-tunnel.svg)](http://microbadger.com/images/henriqueamrl/docker-ssh-tunnel "Get your own image badge on microbadger.com")
- [`v1.2` (*Dockerfile*)](https://github.com/henriqueamrl/docker-ssh-tunnel/blob/v1.2/Dockerfile) [![](https://images.microbdger.com/badges/image/henriqueamrl/docker-ssh-tunnel.svg)](http://microbadger.com/images/henriqueamrl/docker-ssh-tunnel "Get your own image badge on microbadger.com")
- [`v1.1` (*Dockerfile*)](https://github.com/henriqueamrl/docker-ssh-tunnel/blob/v1.1/Dockerfile) [![](https://images.microbdger.com/badges/image/henriqueamrl/docker-ssh-tunnel.svg)](http://microbadger.com/images/henriqueamrl/docker-ssh-tunnel "Get your own image badge on microbadger.com")
- [`v1.0` (*Dockerfile*)](https://github.com/henriqueamrl/docker-ssh-tunnel/blob/v1.0/Dockerfile) [![](https://images.microbdger.com/badges/image/henriqueamrl/docker-ssh-tunnel.svg)](http://microbadger.com/images/henriqueamrl/docker-ssh-tunnel "Get your own image badge on microbadger.com")


For single TCP port applications (database/webserver/debugging access) a SSH tunnel is far faster and simpler than using a VPN like OpenVPN; see this excellent [blog post](https://blog.backslasher.net/ssh-openvpn-tunneling.html) for more info.

For example I use it to create a SSH tunnel from a GCP Kubernetes cluster into an on prem bastion host in order to talk to an on prem MySQL database; it SSHs onto the internal LAN and connects me to the internal on prem MySQL server.

Inspired by https://github.com/iadknet/docker-ssh-client-light and [GCP CloudSQL Proxy](https://cloud.google.com/sql/docs/mysql/sql-proxy)

## Required Parameters

```bash
# local port on your machine/k8s cluster
LOCAL_PORT=3306

# remote port from the machine your SSHing into
REMOTE_PORT=3306

# OPTIONAL defaults to 127.0.0.1
REMOTE_SERVER_IP="my.internal.mariadb.server"

# the bastion/host you're connecting to
SSH_BASTION_HOST="bastion.host"

# OPTIONAL defaults to 22
SSH_PORT=2297

SSH_USER="tunnel_user"

# REQUIRED: One of the following must be set
# SSH_KEY="-----BEGIN OPENSSH PRIVATE KEY-----\n..." # direct key content
# SSH_KEY_FILE="/path/to/your/private/key" # path to file containing key content
```

You must provide the SSH key using either `SSH_KEY` (direct content) or `SSH_KEY_FILE` (path to file containing the key).

## Docker Secrets Support

All environment variables support a `_FILE` suffix for reading values from files (useful for Docker secrets):

```bash
# Instead of setting environment variables directly, you can use _FILE variables:
LOCAL_PORT_FILE=/run/secrets/local_port
REMOTE_PORT_FILE=/run/secrets/remote_port
REMOTE_SERVER_IP_FILE=/run/secrets/remote_server_ip
SSH_BASTION_HOST_FILE=/run/secrets/ssh_bastion_host
SSH_USER_FILE=/run/secrets/ssh_user
SSH_PORT_FILE=/run/secrets/ssh_port
SSH_KEY_FILE=/run/secrets/ssh_key
```

The script will check for `_FILE` variables first. If a `_FILE` variable is set, it will read the value from the specified file. If not set, it will use the regular environment variable.

## Example

```bash
# connect to our mongo server in AWS via a bastion host
# now we can use a connection string like this:
# mongodb://localhost:27017 
# to talk to our AWS mongo install

docker run -it --rm \
-p 27017:27017 \
-e LOCAL_PORT=27017 \
-e REMOTE_PORT=27017 \
-e SSH_BASTION_HOST=34.135.248.162 \
-e REMOTE_SERVER_IP=aws-nlb-mongo-fake.internal-us-east-1.es.amazonaws.com \
-e SSH_USER=ec2-user \
-e SSH_KEY_FILE=/ssh_key/id_rsa \
-v ~/.ssh/id_rsa:/ssh_key/id_rsa:ro \
henriqueamrl/docker-ssh-tunnel

# connection established, now we can mongo away locally
mongo --host localhost --port 27017
```

## Docker Secrets Example

You can use Docker secrets to securely manage all your configuration:

```bash
# Create secrets from your configuration files
echo "27017" | docker secret create local_port -
echo "27017" | docker secret create remote_port -
echo "aws-nlb-mongo-fake.internal-us-east-1.es.amazonaws.com" | docker secret create remote_server_ip -
echo "34.135.248.162" | docker secret create ssh_bastion_host -
echo "ec2-user" | docker secret create ssh_user -
echo "22" | docker secret create ssh_port -

# Run with secrets
docker run -it --rm \
-p 27017:27017 \
-e LOCAL_PORT_FILE=/run/secrets/local_port \
-e REMOTE_PORT_FILE=/run/secrets/remote_port \
-e REMOTE_SERVER_IP_FILE=/run/secrets/remote_server_ip \
-e SSH_BASTION_HOST_FILE=/run/secrets/ssh_bastion_host \
-e SSH_USER_FILE=/run/secrets/ssh_user \
-e SSH_PORT_FILE=/run/secrets/ssh_port \
-e SSH_KEY_FILE=/run/secrets/ssh_key \
--secret local_port \
--secret remote_port \
--secret remote_server_ip \
--secret ssh_bastion_host \
--secret ssh_user \
--secret ssh_port \
--secret ssh_key \
henriqueamrl/docker-ssh-tunnel
```

Or using docker-compose with secrets (see `examples/docker-compose.yaml` for a complete example):

```yaml
services:
  dbtunnel:
    image: henriqueamrl/docker-ssh-tunnel
    environment:
      - LOCAL_PORT_FILE=/run/secrets/local_port
      - REMOTE_PORT_FILE=/run/secrets/remote_port
      - REMOTE_SERVER_IP_FILE=/run/secrets/remote_server_ip
      - SSH_BASTION_HOST_FILE=/run/secrets/ssh_bastion_host
      - SSH_USER_FILE=/run/secrets/ssh_user
      - SSH_PORT_FILE=/run/secrets/ssh_port
      - SSH_KEY_FILE=/run/secrets/ssh_key
    secrets:
      - local_port
      - remote_port
      - remote_server_ip
      - ssh_bastion_host
      - ssh_user
      - ssh_port
      - ssh_key

secrets:
  local_port:
    file: ./secrets/local_port
  remote_port:
    file: ./secrets/remote_port
  remote_server_ip:
    file: ./secrets/remote_server_ip
  ssh_bastion_host:
    file: ./secrets/ssh_bastion_host
  ssh_user:
    file: ./secrets/ssh_user
  ssh_port:
    file: ./secrets/ssh_port
  ssh_key:
    file: ~/.ssh/id_rsa
```

## TODO

- [x] add example `docker-compose.yml`  to `/examples`
- [x] add GitHub Actions for automated Docker Hub deployment
- [ ] add example k8s manifest to `/examples`

## Version

- 2025-01-24 - `v1.9` - Bumps Alpine to `v3.21`
- 2022-08-11 - `v1.8` - Removes Bash, Bumps Alpine to `v3.16`
- 2021-09-12 - `v1.8` - Bumps Alpine to `v3.15`
#!/bin/bash

#############
# Harshit Raj Sinha
#
# This shell scripts installs necessary packages for app server on instance installation
#############

set -euo pipefail

exec > >(tee -a /tmp/user-data.log) 2>&1


sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

##############################################################
# Install git
if ! command -v git >/dev/null 2>&1; then
    sudo apt-get install -y git
fi

# Clone project repository
cd /home/ubuntu
if [ ! -d "spotify-clone-devops" ]; then
    git clone https://github.com/harshitrajsinha/spotify-clone-devops.git
fi
sudo chown -R ubuntu:ubuntu spotify-clone-devops

##############################################################
# Install node

curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
apt-get install -y nodejs

##############################################################
# Install docker
if ! docker --version > /dev/null 2>&1; then
    sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)

    # Add Docker's official GPG key:
    sudo apt update
    sudo apt install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<-EOF
	Types: deb
	URIs: https://download.docker.com/linux/ubuntu
	Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
	Components: stable
	Architectures: $(dpkg --print-architecture)
	Signed-By: /etc/apt/keyrings/docker.asc
EOF

    sudo apt update

    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add docker user group
    sudo groupadd docker || true
    sudo usermod -aG docker $USER
fi

##############################################################

# Download AWS DocumentDB / RDS global CA bundle
if [ ! -f /opt/certs/global-bundle.pem ]; then
    sudo mkdir -p /opt/certs

    sudo curl -fsSL \
      https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem \
      -o /opt/certs/global-bundle.pem

    sudo chmod 444 /opt/certs/global-bundle.pem
fi

# Install mongosh (mongodb shell) to access documentdb
if ! command -v mongosh >/dev/null 2>&1; then
    wget -qO- https://www.mongodb.org/static/pgp/server-8.0.asc | sudo tee /etc/apt/trusted.gpg.d/server-8.0.asc
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
    sudo apt-get update -y
    sudo apt-get install -y mongodb-mongosh
fi

##############################################################
# Create .env file in backend and frontend by fetching values from AWS SSM parameter store
AWS_REGION="us-east-1"
PROJECT_DIR="/home/ubuntu/spotify-clone-devops" # IN user-data, $USER corresponds to root, hence hard-coding user name

if ! command -v aws >/dev/null 2>&1; then
    sudo apt-get install -y unzip
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
fi

BACKEND_ENV_FILE="${PROJECT_DIR}/backend/.env"
> "$BACKEND_ENV_FILE" # Truncate or create file

for name in PORT MONGODB_URI ADMIN_EMAIL NODE_ENV S3_BUCKET_NAME AWS_REGION FRONTEND_URL COGNITO_DOMAIN COGNITO_CLIENT_ID COGNITO_CLIENT_SECRET COGNITO_REDIRECT_URI COGNITO_USER_POOL_ID; do
    value=$(aws ssm get-parameter --name "/spotify/$name" --with-decryption --query "Parameter.Value" --output text --region "$AWS_REGION")
    echo "${name}=${value}" >> "$BACKEND_ENV_FILE"
done

chown ubuntu:ubuntu "$BACKEND_ENV_FILE"
chmod 600 "$BACKEND_ENV_FILE"

FRONTEND_ENV_FILE="${PROJECT_DIR}/frontend/.env"
> "$FRONTEND_ENV_FILE"

for name in VITE_BACKEND_URL VITE_COGNITO_DOMAIN VITE_COGNITO_CLIENT_ID; do
    value=$(aws ssm get-parameter --name "/spotify/$name" --with-decryption --query "Parameter.Value" --output text --region "$AWS_REGION")
    echo "${name}=${value}" >> "$FRONTEND_ENV_FILE"
done

chown ubuntu:ubuntu "$FRONTEND_ENV_FILE"
chmod 600 "$FRONTEND_ENV_FILE"
##############################################################

# Run reverse proxy, backend and frontend service in background through docker compose
cd "${PROJECT_DIR}"
sudo docker compose up -d --build


##############################################################
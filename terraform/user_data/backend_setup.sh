#!/bin/bash

set -eux

# Update installed packages
yum update -y

# Install Docker
amazon-linux-extras install docker -y

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Install Docker Compose
curl -SL https://github.com/docker/compose/releases/download/v2.30.3/docker-compose-linux-x86_64 \
  -o /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose

# Add the ec2-user to the Docker group
usermod -aG docker ec2-user

# Verify installations
docker --version
docker-compose --version
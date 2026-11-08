#!/bin/bash

set -eux

# Update packages
yum update -y

# Configure MongoDB repository
cat <<'EOF' > /etc/yum.repos.d/mongodb-org-7.0.repo
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-7.0.asc
EOF

# Install MongoDB
yum install -y mongodb-org

# Allow MongoDB to accept connections from the private network
sed -i 's/^  bindIp: 127.0.0.1/  bindIp: 0.0.0.0/' /etc/mongod.conf

# Start MongoDB
systemctl enable mongod
systemctl start mongod

# Verify MongoDB service
systemctl status mongod --no-pager
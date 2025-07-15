#!/bin/bash

# Startup script for GCP compute instances
# This script runs when the instance boots

# Update system packages
apt-get update
apt-get upgrade -y

# Install essential packages
apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    htop \
    fail2ban \
    ufw

# Configure basic firewall
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow from 10.0.0.0/8 to any port 22
ufw allow from 172.16.0.0/12 to any port 22
ufw allow from 192.168.0.0/16 to any port 22

# Configure fail2ban for SSH protection
systemctl enable fail2ban
systemctl start fail2ban

# Install Google Cloud Ops Agent for monitoring
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install

# Create application directory
mkdir -p /opt/app
chown -R www-data:www-data /opt/app

# Log startup completion
echo "$(date): Startup script completed" >> /var/log/startup.log

# Signal completion to metadata
curl -X PUT --data "startup-complete" \
    "http://metadata.google.internal/computeMetadata/v1/instance/attributes/startup-status" \
    -H "Metadata-Flavor: Google"
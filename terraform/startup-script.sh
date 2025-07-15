#!/bin/bash

# Update system
apt-get update
apt-get upgrade -y

# Install basic packages
apt-get install -y \
    curl \
    wget \
    git \
    htop \
    nginx \
    unzip \
    software-properties-common

# Install Google Cloud SDK
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
apt-get update
apt-get install -y google-cloud-sdk

# Install PostgreSQL client
apt-get install -y postgresql-client-14

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Start and enable services
systemctl start docker
systemctl enable docker
systemctl start nginx
systemctl enable nginx

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Configure nginx basic page
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>TopCards Infrastructure</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f4f4f4; }
        .container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; text-align: center; }
        .info { background: #e8f4fd; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .status { color: #28a745; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 TopCards Infrastructure</h1>
        <div class="info">
            <h3>Server Information</h3>
            <p><strong>Hostname:</strong> $(hostname)</p>
            <p><strong>Instance:</strong> $(curl -s http://metadata.google.internal/computeMetadata/v1/instance/name -H "Metadata-Flavor: Google")</p>
            <p><strong>Zone:</strong> $(curl -s http://metadata.google.internal/computeMetadata/v1/instance/zone -H "Metadata-Flavor: Google" | cut -d/ -f4)</p>
            <p><strong>Status:</strong> <span class="status">✅ Online</span></p>
        </div>
        <div class="info">
            <h3>Services</h3>
            <p>• Nginx: Running</p>
            <p>• Docker: Installed</p>
            <p>• Google Cloud SDK: Installed</p>
            <p>• PostgreSQL Client: Installed</p>
        </div>
        <div class="info">
            <h3>Database Connection</h3>
            <p>• Cloud SQL PostgreSQL: Private network</p>
            <p>• SSL/TLS: Required</p>
            <p>• Credentials: Secret Manager</p>
        </div>
    </div>
</body>
</html>
EOF

# Set up log rotation
cat > /etc/logrotate.d/app-logs << EOF
/var/log/app/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
EOF

# Create log directory
mkdir -p /var/log/app
chown ubuntu:ubuntu /var/log/app

# Create a simple monitoring script
cat > /usr/local/bin/health-check.sh << 'EOF'
#!/bin/bash
# Simple health check script

LOG_FILE="/var/log/app/health-check.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Check nginx
if systemctl is-active --quiet nginx; then
    echo "$TIMESTAMP - Nginx: OK" >> $LOG_FILE
else
    echo "$TIMESTAMP - Nginx: FAILED" >> $LOG_FILE
fi

# Check disk space
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -lt 80 ]; then
    echo "$TIMESTAMP - Disk Usage: OK ($DISK_USAGE%)" >> $LOG_FILE
else
    echo "$TIMESTAMP - Disk Usage: WARNING ($DISK_USAGE%)" >> $LOG_FILE
fi

# Check memory
MEM_USAGE=$(free | awk 'FNR==2{printf "%.0f", $3/($3+$4)*100}')
echo "$TIMESTAMP - Memory Usage: $MEM_USAGE%" >> $LOG_FILE
EOF

chmod +x /usr/local/bin/health-check.sh

# Set up cron job for health checks
echo "*/5 * * * * /usr/local/bin/health-check.sh" | crontab -u ubuntu -

# Final status
echo "Startup script completed successfully" > /var/log/startup-complete.log
date >> /var/log/startup-complete.log
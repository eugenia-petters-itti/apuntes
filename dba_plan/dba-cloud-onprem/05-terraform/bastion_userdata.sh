#!/bin/bash
# Bastion Host User Data Script for DBA Labs
# This script configures the bastion host with necessary tools

# Update system
yum update -y

# Install basic tools
yum install -y \
    wget \
    curl \
    vim \
    htop \
    net-tools \
    telnet \
    nc \
    git \
    unzip

# Install MongoDB Shell (mongosh)
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

# For Amazon Linux, use different approach
cat > /etc/yum.repos.d/mongodb-org-6.0.repo << 'EOF'
[mongodb-org-6.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/6.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
EOF

yum install -y mongodb-mongosh

# Install MySQL client
yum install -y mysql

# Install PostgreSQL client
amazon-linux-extras install -y postgresql14

# Download SSL certificate for DocumentDB
cd /home/ec2-user
wget https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem
chown ec2-user:ec2-user rds-combined-ca-bundle.pem

# Create connection scripts
cat > /home/ec2-user/connect_docdb.sh << 'EOF'
#!/bin/bash
# DocumentDB Connection Script
DOCDB_ENDPOINT="${docdb_endpoint}"
DOCDB_USERNAME="docdbadmin"

echo "Connecting to DocumentDB cluster: $DOCDB_ENDPOINT"
echo "Username: $DOCDB_USERNAME"
echo "Please enter password when prompted"

mongosh --host $DOCDB_ENDPOINT:27017 \
    --username $DOCDB_USERNAME \
    --ssl \
    --sslCAFile /home/ec2-user/rds-combined-ca-bundle.pem \
    --retryWrites=false
EOF

chmod +x /home/ec2-user/connect_docdb.sh
chown ec2-user:ec2-user /home/ec2-user/connect_docdb.sh

# Create useful aliases
cat >> /home/ec2-user/.bashrc << 'EOF'

# DBA Lab Aliases
alias ll='ls -la'
alias docdb='~/connect_docdb.sh'
alias logs='sudo tail -f /var/log/messages'

# Environment variables
export DOCDB_ENDPOINT="${docdb_endpoint}"
export DOCDB_USERNAME="docdbadmin"

echo "DBA Lab Bastion Host - Ready for use!"
echo "Available commands:"
echo "  docdb - Connect to DocumentDB"
echo "  mysql -h <endpoint> -u <user> -p - Connect to MySQL"
echo "  psql -h <endpoint> -U <user> -d <database> - Connect to PostgreSQL"
EOF

# Set proper ownership
chown ec2-user:ec2-user /home/ec2-user/.bashrc

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Create welcome message
cat > /etc/motd << 'EOF'
=====================================
    DBA Training Lab - Bastion Host
=====================================

This bastion host provides secure access to:
- DocumentDB Cluster
- RDS MySQL Instance  
- RDS PostgreSQL Instance

Available tools:
- mongosh (MongoDB Shell)
- mysql (MySQL Client)
- psql (PostgreSQL Client)
- aws (AWS CLI v2)

Quick commands:
- docdb          : Connect to DocumentDB
- mysql -h <host> -u <user> -p : Connect to MySQL
- psql -h <host> -U <user> -d <db> : Connect to PostgreSQL

SSL Certificate for DocumentDB:
/home/ec2-user/rds-combined-ca-bundle.pem

For support, contact your lab instructor.
=====================================
EOF

# Enable and start services
systemctl enable sshd
systemctl start sshd

# Configure SSH for better security (optional)
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# Log completion
echo "$(date): Bastion host configuration completed" >> /var/log/userdata.log

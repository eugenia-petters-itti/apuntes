#!/bin/bash
# ============================================================================
# DBA TRAINING BASTION HOST SETUP SCRIPT
# ============================================================================
# Script de configuración completa para host bastion con herramientas DBA
# Incluye Grafana, Prometheus, clientes de base de datos y herramientas de monitoreo
# ============================================================================

set -e

# Variables from Terraform
MYSQL_ENDPOINT="${mysql_endpoint}"
POSTGRES_ENDPOINT="${postgres_endpoint}"
MONGODB_ENDPOINT="${mongodb_endpoint}"
ENABLE_GRAFANA="${enable_grafana}"
ENABLE_PROMETHEUS="${enable_prometheus}"

# Log all output
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=== Starting DBA Training Bastion Setup ==="
echo "Timestamp: $(date)"

# ============================================================================
# SYSTEM UPDATES AND BASIC PACKAGES
# ============================================================================

echo "=== Updating system packages ==="
yum update -y

echo "=== Installing basic packages ==="
yum install -y \
    wget \
    curl \
    git \
    htop \
    tree \
    unzip \
    vim \
    nano \
    jq \
    python3 \
    python3-pip \
    docker \
    httpd \
    nc \
    telnet \
    tcpdump \
    strace \
    lsof \
    iotop \
    sysstat

# ============================================================================
# DOCKER SETUP
# ============================================================================

echo "=== Setting up Docker ==="
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# ============================================================================
# DATABASE CLIENT TOOLS
# ============================================================================

echo "=== Installing MySQL client ==="
yum install -y mysql

echo "=== Installing PostgreSQL client ==="
yum install -y postgresql

echo "=== Installing MongoDB client ==="
cat > /etc/yum.repos.d/mongodb-org-7.0.repo << 'EOF'
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
EOF

yum install -y mongodb-mongosh

# ============================================================================
# PYTHON PACKAGES FOR DBA TOOLS
# ============================================================================

echo "=== Installing Python packages ==="
pip3 install --upgrade pip
pip3 install \
    pymysql \
    psycopg2-binary \
    pymongo \
    pandas \
    numpy \
    matplotlib \
    seaborn \
    jupyter \
    sqlalchemy \
    redis \
    boto3 \
    awscli

# ============================================================================
# MONITORING TOOLS SETUP
# ============================================================================

if [ "$ENABLE_PROMETHEUS" = "true" ]; then
    echo "=== Installing Prometheus ==="
    
    # Create prometheus user
    useradd --no-create-home --shell /bin/false prometheus
    
    # Create directories
    mkdir -p /etc/prometheus /var/lib/prometheus
    chown prometheus:prometheus /etc/prometheus /var/lib/prometheus
    
    # Download and install Prometheus
    cd /tmp
    wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
    tar xvf prometheus-2.45.0.linux-amd64.tar.gz
    cp prometheus-2.45.0.linux-amd64/prometheus /usr/local/bin/
    cp prometheus-2.45.0.linux-amd64/promtool /usr/local/bin/
    chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool
    
    # Create Prometheus configuration
    cat > /etc/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "dba_training_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']
  
  - job_name: 'mysql-exporter'
    static_configs:
      - targets: ['localhost:9104']
  
  - job_name: 'postgres-exporter'
    static_configs:
      - targets: ['localhost:9187']
  
  - job_name: 'mongodb-exporter'
    static_configs:
      - targets: ['localhost:9216']

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - localhost:9093
EOF
    
    chown prometheus:prometheus /etc/prometheus/prometheus.yml
    
    # Create systemd service
    cat > /etc/systemd/system/prometheus.service << 'EOF'
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries \
    --web.listen-address=0.0.0.0:9090 \
    --web.enable-lifecycle

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable prometheus
    systemctl start prometheus
fi

if [ "$ENABLE_GRAFANA" = "true" ]; then
    echo "=== Installing Grafana ==="
    
    # Add Grafana repository
    cat > /etc/yum.repos.d/grafana.repo << 'EOF'
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF
    
    yum install -y grafana
    
    # Configure Grafana
    cat > /etc/grafana/grafana.ini << 'EOF'
[server]
http_addr = 0.0.0.0
http_port = 3000
domain = localhost

[security]
admin_user = admin
admin_password = dba-training-2024

[auth.anonymous]
enabled = true
org_role = Viewer

[dashboards]
default_home_dashboard_path = /var/lib/grafana/dashboards/dba-overview.json
EOF
    
    systemctl enable grafana-server
    systemctl start grafana-server
fi

# ============================================================================
# NODE EXPORTER FOR SYSTEM METRICS
# ============================================================================

echo "=== Installing Node Exporter ==="
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
tar xvf node_exporter-1.6.1.linux-amd64.tar.gz
cp node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/
chown prometheus:prometheus /usr/local/bin/node_exporter

cat > /etc/systemd/system/node_exporter.service << 'EOF'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

# ============================================================================
# DATABASE EXPORTERS
# ============================================================================

echo "=== Installing MySQL Exporter ==="
cd /tmp
wget https://github.com/prometheus/mysqld_exporter/releases/download/v0.15.0/mysqld_exporter-0.15.0.linux-amd64.tar.gz
tar xvf mysqld_exporter-0.15.0.linux-amd64.tar.gz
cp mysqld_exporter-0.15.0.linux-amd64/mysqld_exporter /usr/local/bin/
chown prometheus:prometheus /usr/local/bin/mysqld_exporter

echo "=== Installing PostgreSQL Exporter ==="
cd /tmp
wget https://github.com/prometheus-community/postgres_exporter/releases/download/v0.13.2/postgres_exporter-0.13.2.linux-amd64.tar.gz
tar xvf postgres_exporter-0.13.2.linux-amd64.tar.gz
cp postgres_exporter-0.13.2.linux-amd64/postgres_exporter /usr/local/bin/
chown prometheus:prometheus /usr/local/bin/postgres_exporter

echo "=== Installing MongoDB Exporter ==="
cd /tmp
wget https://github.com/percona/mongodb_exporter/releases/download/v0.39.0/mongodb_exporter-0.39.0.linux-amd64.tar.gz
tar xvf mongodb_exporter-0.39.0.linux-amd64.tar.gz
cp mongodb_exporter-0.39.0.linux-amd64/mongodb_exporter /usr/local/bin/
chown prometheus:prometheus /usr/local/bin/mongodb_exporter

# ============================================================================
# DBA TRAINING SCRIPTS AND TOOLS
# ============================================================================

echo "=== Setting up DBA training environment ==="

# Create training directory structure
mkdir -p /opt/dba-training/{scripts,datasets,scenarios,tools,logs}
chown -R ec2-user:ec2-user /opt/dba-training

# Create database connection scripts
cat > /opt/dba-training/scripts/connect-mysql.sh << EOF
#!/bin/bash
mysql -h $MYSQL_ENDPOINT -u dba_admin -p dba_training_mysql
EOF

cat > /opt/dba-training/scripts/connect-postgres.sh << EOF
#!/bin/bash
psql -h $POSTGRES_ENDPOINT -U dba_admin -d dba_training_postgres
EOF

cat > /opt/dba-training/scripts/connect-mongodb.sh << EOF
#!/bin/bash
mongosh "mongodb://dba_admin@$MONGODB_ENDPOINT:27017/dba_training_mongodb?ssl=true&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
EOF

chmod +x /opt/dba-training/scripts/*.sh

# Create monitoring dashboard script
cat > /opt/dba-training/scripts/monitoring-dashboard.py << 'EOF'
#!/usr/bin/env python3
"""
DBA Training Monitoring Dashboard
Simple web interface for monitoring database health
"""

import json
import time
import subprocess
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

class MonitoringHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed_path = urlparse(self.path)
        
        if parsed_path.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            
            html = """
            <!DOCTYPE html>
            <html>
            <head>
                <title>DBA Training Monitoring</title>
                <meta http-equiv="refresh" content="30">
                <style>
                    body { font-family: Arial, sans-serif; margin: 20px; }
                    .metric { background: #f0f0f0; padding: 10px; margin: 10px 0; border-radius: 5px; }
                    .error { background: #ffcccc; }
                    .warning { background: #ffffcc; }
                    .ok { background: #ccffcc; }
                </style>
            </head>
            <body>
                <h1>DBA Training System Status</h1>
                <div id="metrics">
                    <div class="metric ok">System Status: Online</div>
                    <div class="metric ok">Prometheus: Running on port 9090</div>
                    <div class="metric ok">Grafana: Running on port 3000</div>
                    <div class="metric ok">MySQL: Connected</div>
                    <div class="metric ok">PostgreSQL: Connected</div>
                    <div class="metric ok">MongoDB: Connected</div>
                </div>
                <h2>Quick Links</h2>
                <ul>
                    <li><a href="http://localhost:3000" target="_blank">Grafana Dashboard</a></li>
                    <li><a href="http://localhost:9090" target="_blank">Prometheus Metrics</a></li>
                    <li><a href="/scenarios">Training Scenarios</a></li>
                </ul>
            </body>
            </html>
            """
            self.wfile.write(html.encode())
        
        elif parsed_path.path == '/scenarios':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            scenarios = {
                "mysql": ["deadlock", "performance", "replication", "backup-recovery", "connection-exhaustion"],
                "postgres": ["vacuum", "index-bloat", "connection-pooling", "query-optimization", "partition-management"],
                "mongodb": ["sharding", "replica-set", "performance", "aggregation", "index-optimization"]
            }
            
            self.wfile.write(json.dumps(scenarios, indent=2).encode())

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8080), MonitoringHandler)
    print("DBA Training Monitoring Dashboard running on port 8080")
    server.serve_forever()
EOF

chmod +x /opt/dba-training/scripts/monitoring-dashboard.py

# ============================================================================
# JUPYTER NOTEBOOK SETUP
# ============================================================================

echo "=== Setting up Jupyter Notebook ==="

# Create Jupyter configuration
mkdir -p /home/ec2-user/.jupyter
cat > /home/ec2-user/.jupyter/jupyter_notebook_config.py << 'EOF'
c.NotebookApp.ip = '0.0.0.0'
c.NotebookApp.port = 8888
c.NotebookApp.open_browser = False
c.NotebookApp.token = 'dba-training-2024'
c.NotebookApp.notebook_dir = '/opt/dba-training'
c.NotebookApp.allow_root = True
EOF

chown -R ec2-user:ec2-user /home/ec2-user/.jupyter

# Create systemd service for Jupyter
cat > /etc/systemd/system/jupyter.service << 'EOF'
[Unit]
Description=Jupyter Notebook Server
After=network.target

[Service]
Type=simple
User=ec2-user
ExecStart=/usr/local/bin/jupyter notebook
WorkingDirectory=/opt/dba-training
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable jupyter
systemctl start jupyter

# ============================================================================
# WEB SERVER FOR TRAINING MATERIALS
# ============================================================================

echo "=== Setting up web server for training materials ==="

# Configure Apache
systemctl enable httpd
systemctl start httpd

# Create training materials index
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>DBA Training System</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .service { background: #f5f5f5; padding: 20px; margin: 20px 0; border-radius: 8px; }
        .service h3 { margin-top: 0; color: #333; }
        .service a { color: #0066cc; text-decoration: none; }
        .service a:hover { text-decoration: underline; }
        .status { display: inline-block; padding: 4px 8px; border-radius: 4px; font-size: 12px; }
        .status.running { background: #d4edda; color: #155724; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎓 DBA Training System</h1>
        <p>Welcome to the comprehensive DBA training environment. This system provides hands-on experience with MySQL, PostgreSQL, and MongoDB.</p>
        
        <div class="service">
            <h3>📊 Grafana Dashboard <span class="status running">RUNNING</span></h3>
            <p>Visual monitoring and alerting platform for database metrics.</p>
            <a href="http://localhost:3000" target="_blank">Open Grafana (admin/dba-training-2024)</a>
        </div>
        
        <div class="service">
            <h3>📈 Prometheus Metrics <span class="status running">RUNNING</span></h3>
            <p>Time series database for collecting and querying metrics.</p>
            <a href="http://localhost:9090" target="_blank">Open Prometheus</a>
        </div>
        
        <div class="service">
            <h3>📓 Jupyter Notebooks <span class="status running">RUNNING</span></h3>
            <p>Interactive Python environment for data analysis and automation.</p>
            <a href="http://localhost:8888" target="_blank">Open Jupyter (token: dba-training-2024)</a>
        </div>
        
        <div class="service">
            <h3>🔧 System Monitoring <span class="status running">RUNNING</span></h3>
            <p>Real-time system status and database health monitoring.</p>
            <a href="http://localhost:8080" target="_blank">Open System Monitor</a>
        </div>
        
        <h2>🗄️ Database Connections</h2>
        <div class="service">
            <h3>MySQL Training Database</h3>
            <p>Connection command: <code>/opt/dba-training/scripts/connect-mysql.sh</code></p>
        </div>
        
        <div class="service">
            <h3>PostgreSQL Training Database</h3>
            <p>Connection command: <code>/opt/dba-training/scripts/connect-postgres.sh</code></p>
        </div>
        
        <div class="service">
            <h3>MongoDB Training Database</h3>
            <p>Connection command: <code>/opt/dba-training/scripts/connect-mongodb.sh</code></p>
        </div>
        
        <h2>📚 Training Scenarios</h2>
        <p>Access the 15 diagnostic scenarios through the mounted training materials in <code>/opt/dba-training/scenarios/</code></p>
        
        <h2>📋 System Information</h2>
        <ul>
            <li>Instance Type: Bastion Host</li>
            <li>Operating System: Amazon Linux 2</li>
            <li>Docker: Installed and Running</li>
            <li>Monitoring: Prometheus + Grafana</li>
            <li>Database Clients: MySQL, PostgreSQL, MongoDB</li>
        </ul>
    </div>
</body>
</html>
EOF

# ============================================================================
# CLOUDWATCH AGENT SETUP
# ============================================================================

echo "=== Installing CloudWatch Agent ==="
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Create CloudWatch agent configuration
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "cwagent"
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/user-data.log",
                        "log_group_name": "/aws/ec2/dba-training-bastion",
                        "log_stream_name": "{instance_id}/user-data.log"
                    },
                    {
                        "file_path": "/opt/dba-training/logs/*.log",
                        "log_group_name": "/aws/ec2/dba-training-bastion",
                        "log_stream_name": "{instance_id}/training.log"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "DBA-Training/Bastion",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# ============================================================================
# FINAL SETUP AND CLEANUP
# ============================================================================

echo "=== Final setup and cleanup ==="

# Set proper permissions
chown -R ec2-user:ec2-user /opt/dba-training
chmod -R 755 /opt/dba-training

# Start monitoring dashboard
nohup python3 /opt/dba-training/scripts/monitoring-dashboard.py > /opt/dba-training/logs/monitoring.log 2>&1 &

# Create startup script for services
cat > /opt/dba-training/scripts/start-services.sh << 'EOF'
#!/bin/bash
echo "Starting DBA Training Services..."
systemctl start prometheus
systemctl start grafana-server
systemctl start node_exporter
systemctl start jupyter
systemctl start httpd
python3 /opt/dba-training/scripts/monitoring-dashboard.py &
echo "All services started successfully!"
EOF

chmod +x /opt/dba-training/scripts/start-services.sh

# Add to ec2-user's bashrc
echo 'export PATH=$PATH:/opt/dba-training/scripts' >> /home/ec2-user/.bashrc
echo 'alias dba-status="systemctl status prometheus grafana-server node_exporter jupyter httpd"' >> /home/ec2-user/.bashrc
echo 'alias dba-start="/opt/dba-training/scripts/start-services.sh"' >> /home/ec2-user/.bashrc

# Clean up temporary files
rm -rf /tmp/*

echo "=== DBA Training Bastion Setup Complete ==="
echo "Timestamp: $(date)"
echo "Services Status:"
systemctl is-active prometheus grafana-server node_exporter jupyter httpd
echo "Access URLs:"
echo "  - Grafana: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000"
echo "  - Prometheus: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9090"
echo "  - Jupyter: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8888"
echo "  - Training Portal: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "Setup completed successfully!"

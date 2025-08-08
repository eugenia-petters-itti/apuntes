# Terraform Configuration for DBA Lab Infrastructure
# Version: 1.0
# Description: Complete infrastructure setup for DBA Cloud OnPrem Junior labs

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Variables
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dba-lab"
}

variable "student_count" {
  description = "Number of students (affects resource sizing)"
  type        = number
  default     = 20
}

variable "lab_duration_days" {
  description = "Duration of lab in days (affects backup retention)"
  type        = number
  default     = 35
}

variable "db_password" {
  description = "Master password for databases"
  type        = string
  sensitive   = true
  default     = "LabPassword123!"
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access databases"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Restrict in production
}

# Provider configuration
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "DBA-Training-Lab"
      ManagedBy   = "Terraform"
      CreatedDate = timestamp()
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Random password for additional security
resource "random_password" "db_passwords" {
  for_each = toset(["mysql", "postgres", "docdb"])
  
  length  = 16
  special = true
}

# Security Groups
resource "aws_security_group" "rds_mysql" {
  name_prefix = "${var.environment}-rds-mysql-"
  vpc_id      = data.aws_vpc.default.id
  description = "Security group for RDS MySQL instances"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "MySQL access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "${var.environment}-rds-mysql-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "rds_postgres" {
  name_prefix = "${var.environment}-rds-postgres-"
  vpc_id      = data.aws_vpc.default.id
  description = "Security group for RDS PostgreSQL instances"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "PostgreSQL access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "${var.environment}-rds-postgres-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "docdb" {
  name_prefix = "${var.environment}-docdb-"
  vpc_id      = data.aws_vpc.default.id
  description = "Security group for DocumentDB cluster"

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "DocumentDB access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "${var.environment}-docdb-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "bastion" {
  name_prefix = "${var.environment}-bastion-"
  vpc_id      = data.aws_vpc.default.id
  description = "Security group for bastion host"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "SSH access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "${var.environment}-bastion-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# DB Subnet Groups
resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "${var.environment}-db-subnet-group"
  }
}

resource "aws_docdb_subnet_group" "main" {
  name       = "${var.environment}-docdb-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "${var.environment}-docdb-subnet-group"
  }
}

# Parameter Groups
resource "aws_db_parameter_group" "mysql" {
  family = "mysql8.0"
  name   = "${var.environment}-mysql-params"

  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  }

  parameter {
    name  = "max_connections"
    value = "200"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  parameter {
    name  = "log_bin_trust_function_creators"
    value = "1"
  }

  parameter {
    name  = "binlog_format"
    value = "ROW"
  }

  tags = {
    Name = "${var.environment}-mysql-params"
  }
}

resource "aws_db_parameter_group" "postgres" {
  family = "postgres14"
  name   = "${var.environment}-postgres-params"

  parameter {
    name  = "shared_buffers"
    value = "{DBInstanceClassMemory/4}"
  }

  parameter {
    name  = "work_mem"
    value = "4096"
  }

  parameter {
    name  = "maintenance_work_mem"
    value = "65536"
  }

  parameter {
    name  = "effective_cache_size"
    value = "{DBInstanceClassMemory*3/4}"
  }

  parameter {
    name  = "log_statement"
    value = "ddl"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  tags = {
    Name = "${var.environment}-postgres-params"
  }
}

resource "aws_docdb_cluster_parameter_group" "main" {
  family = "docdb4.0"
  name   = "${var.environment}-docdb-params"

  parameter {
    name  = "audit_logs"
    value = "enabled"
  }

  parameter {
    name  = "profiler"
    value = "enabled"
  }

  parameter {
    name  = "profiler_threshold_ms"
    value = "1000"
  }

  tags = {
    Name = "${var.environment}-docdb-params"
  }
}

# IAM Role for Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.environment}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.environment}-rds-monitoring-role"
  }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# RDS MySQL Instance
resource "aws_db_instance" "mysql_lab" {
  identifier = "${var.environment}-mysql-lab"

  # Engine configuration
  engine         = "mysql"
  engine_version = "8.0.35"
  instance_class = "db.t3.micro"

  # Database configuration
  db_name  = "labdb"
  username = "admin"
  password = coalesce(var.db_password, random_password.db_passwords["mysql"].result)

  # Storage configuration
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true

  # Network configuration
  vpc_security_group_ids = [aws_security_group.rds_mysql.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  publicly_accessible    = true

  # Backup configuration
  backup_retention_period = var.lab_duration_days
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  copy_tags_to_snapshot  = true

  # Parameter group
  parameter_group_name = aws_db_parameter_group.mysql.name

  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  # Performance Insights
  performance_insights_enabled = true
  performance_insights_retention_period = 7

  # Other settings
  auto_minor_version_upgrade = true
  deletion_protection       = false
  skip_final_snapshot      = true
  final_snapshot_identifier = "${var.environment}-mysql-final-snapshot"

  tags = {
    Name = "${var.environment}-mysql-lab"
    Type = "MySQL"
  }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "postgres_lab" {
  identifier = "${var.environment}-postgres-lab"

  # Engine configuration
  engine         = "postgres"
  engine_version = "14.9"
  instance_class = "db.t3.micro"

  # Database configuration
  db_name  = "labdb"
  username = "postgres"
  password = coalesce(var.db_password, random_password.db_passwords["postgres"].result)

  # Storage configuration
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true

  # Network configuration
  vpc_security_group_ids = [aws_security_group.rds_postgres.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  publicly_accessible    = true

  # Backup configuration
  backup_retention_period = var.lab_duration_days
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  copy_tags_to_snapshot  = true

  # Parameter group
  parameter_group_name = aws_db_parameter_group.postgres.name

  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  # Performance Insights
  performance_insights_enabled = true
  performance_insights_retention_period = 7

  # Other settings
  auto_minor_version_upgrade = true
  deletion_protection       = false
  skip_final_snapshot      = true
  final_snapshot_identifier = "${var.environment}-postgres-final-snapshot"

  tags = {
    Name = "${var.environment}-postgres-lab"
    Type = "PostgreSQL"
  }
}

# DocumentDB Cluster
resource "aws_docdb_cluster" "main" {
  cluster_identifier = "${var.environment}-docdb-cluster"
  engine             = "docdb"
  engine_version     = "4.0.0"

  master_username = "docdbadmin"
  master_password = coalesce(var.db_password, random_password.db_passwords["docdb"].result)

  vpc_security_group_ids          = [aws_security_group.docdb.id]
  db_subnet_group_name           = aws_docdb_subnet_group.main.name
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.main.name

  backup_retention_period = var.lab_duration_days
  preferred_backup_window = "03:00-04:00"
  preferred_maintenance_window = "sun:04:00-sun:05:00"

  storage_encrypted = true
  apply_immediately = true

  skip_final_snapshot       = true
  final_snapshot_identifier = "${var.environment}-docdb-final-snapshot"

  enabled_cloudwatch_logs_exports = ["audit", "profiler"]

  tags = {
    Name = "${var.environment}-docdb-cluster"
    Type = "DocumentDB"
  }
}

# DocumentDB Instance
resource "aws_docdb_cluster_instance" "main" {
  count              = 1
  identifier         = "${var.environment}-docdb-instance-${count.index + 1}"
  cluster_identifier = aws_docdb_cluster.main.id
  instance_class     = "db.t3.medium"

  performance_insights_enabled = true

  tags = {
    Name = "${var.environment}-docdb-instance-${count.index + 1}"
    Type = "DocumentDB"
  }
}

# Key Pair for EC2 instances
resource "aws_key_pair" "lab_key" {
  key_name   = "${var.environment}-lab-key"
  public_key = file("~/.ssh/id_rsa.pub") # Ensure this file exists

  tags = {
    Name = "${var.environment}-lab-key"
  }
}

# Bastion Host
resource "aws_instance" "bastion" {
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI (update as needed)
  instance_type = "t2.micro"
  key_name      = aws_key_pair.lab_key.key_name

  vpc_security_group_ids = [aws_security_group.bastion.id]
  subnet_id              = data.aws_subnets.default.ids[0]

  associate_public_ip_address = true

  user_data = base64encode(templatefile("${path.module}/bastion_userdata.sh", {
    docdb_endpoint = aws_docdb_cluster.main.endpoint
  }))

  tags = {
    Name = "${var.environment}-bastion"
    Type = "Bastion"
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "mysql_error" {
  name              = "/aws/rds/instance/${aws_db_instance.mysql_lab.id}/error"
  retention_in_days = var.lab_duration_days

  tags = {
    Name = "${var.environment}-mysql-error-logs"
  }
}

resource "aws_cloudwatch_log_group" "mysql_slow" {
  name              = "/aws/rds/instance/${aws_db_instance.mysql_lab.id}/slowquery"
  retention_in_days = var.lab_duration_days

  tags = {
    Name = "${var.environment}-mysql-slow-logs"
  }
}

resource "aws_cloudwatch_log_group" "postgres" {
  name              = "/aws/rds/instance/${aws_db_instance.postgres_lab.id}/postgresql"
  retention_in_days = var.lab_duration_days

  tags = {
    Name = "${var.environment}-postgres-logs"
  }
}

# SNS Topic for Alerts
resource "aws_sns_topic" "db_alerts" {
  name = "${var.environment}-db-alerts"

  tags = {
    Name = "${var.environment}-db-alerts"
  }
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "mysql_cpu" {
  alarm_name          = "${var.environment}-mysql-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors MySQL CPU utilization"
  alarm_actions       = [aws_sns_topic.db_alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.mysql_lab.id
  }

  tags = {
    Name = "${var.environment}-mysql-cpu-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "postgres_cpu" {
  alarm_name          = "${var.environment}-postgres-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors PostgreSQL CPU utilization"
  alarm_actions       = [aws_sns_topic.db_alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres_lab.id
  }

  tags = {
    Name = "${var.environment}-postgres-cpu-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "docdb_cpu" {
  alarm_name          = "${var.environment}-docdb-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/DocDB"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors DocumentDB CPU utilization"
  alarm_actions       = [aws_sns_topic.db_alerts.arn]

  dimensions = {
    DBClusterIdentifier = aws_docdb_cluster.main.id
  }

  tags = {
    Name = "${var.environment}-docdb-cpu-alarm"
  }
}

# Outputs
output "mysql_endpoint" {
  description = "RDS MySQL endpoint"
  value       = aws_db_instance.mysql_lab.endpoint
}

output "mysql_port" {
  description = "RDS MySQL port"
  value       = aws_db_instance.mysql_lab.port
}

output "postgres_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.postgres_lab.endpoint
}

output "postgres_port" {
  description = "RDS PostgreSQL port"
  value       = aws_db_instance.postgres_lab.port
}

output "docdb_endpoint" {
  description = "DocumentDB cluster endpoint"
  value       = aws_docdb_cluster.main.endpoint
}

output "docdb_port" {
  description = "DocumentDB port"
  value       = aws_docdb_cluster.main.port
}

output "bastion_public_ip" {
  description = "Bastion host public IP"
  value       = aws_instance.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Bastion host private IP"
  value       = aws_instance.bastion.private_ip
}

output "connection_commands" {
  description = "Connection commands for databases"
  value = {
    mysql = "mysql -h ${aws_db_instance.mysql_lab.endpoint} -u admin -p"
    postgres = "psql -h ${aws_db_instance.postgres_lab.endpoint} -U postgres -d labdb"
    docdb = "mongosh --host ${aws_docdb_cluster.main.endpoint}:${aws_docdb_cluster.main.port} --username docdbadmin --password --ssl --sslCAFile rds-combined-ca-bundle.pem"
    bastion = "ssh -i ~/.ssh/id_rsa ec2-user@${aws_instance.bastion.public_ip}"
  }
}

output "database_passwords" {
  description = "Database passwords (sensitive)"
  value = {
    mysql = coalesce(var.db_password, random_password.db_passwords["mysql"].result)
    postgres = coalesce(var.db_password, random_password.db_passwords["postgres"].result)
    docdb = coalesce(var.db_password, random_password.db_passwords["docdb"].result)
  }
  sensitive = true
}

output "security_group_ids" {
  description = "Security group IDs"
  value = {
    mysql = aws_security_group.rds_mysql.id
    postgres = aws_security_group.rds_postgres.id
    docdb = aws_security_group.docdb.id
    bastion = aws_security_group.bastion.id
  }
}

output "cloudwatch_log_groups" {
  description = "CloudWatch log group names"
  value = {
    mysql_error = aws_cloudwatch_log_group.mysql_error.name
    mysql_slow = aws_cloudwatch_log_group.mysql_slow.name
    postgres = aws_cloudwatch_log_group.postgres.name
  }
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.db_alerts.arn
}

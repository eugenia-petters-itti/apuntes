# ============================================================================
# DBA TRAINING SYSTEM - TERRAFORM OUTPUTS
# ============================================================================
# Outputs completos para acceso y gestión del sistema de entrenamiento DBA
# Incluye información de conexión, credenciales y URLs de acceso
# ============================================================================

# ============================================================================
# NETWORK OUTPUTS
# ============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.vpc.database_subnets
}

output "nat_gateway_ids" {
  description = "List of IDs of the NAT Gateways"
  value       = module.vpc.natgw_ids
}

# ============================================================================
# BASTION HOST OUTPUTS
# ============================================================================

output "bastion_instance_id" {
  description = "ID of the bastion instance"
  value       = module.bastion.instance_id
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = module.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Private IP address of the bastion host"
  value       = module.bastion.private_ip
}

output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = module.bastion.security_group_id
}

# ============================================================================
# DATABASE OUTPUTS
# ============================================================================

output "mysql_endpoint" {
  description = "RDS MySQL instance endpoint"
  value       = module.rds_mysql.db_instance_endpoint
}

output "mysql_port" {
  description = "RDS MySQL instance port"
  value       = module.rds_mysql.db_instance_port
}

output "mysql_database_name" {
  description = "RDS MySQL database name"
  value       = module.rds_mysql.db_instance_name
}

output "mysql_username" {
  description = "RDS MySQL instance master username"
  value       = module.rds_mysql.db_instance_username
  sensitive   = true
}

output "postgres_endpoint" {
  description = "RDS PostgreSQL instance endpoint"
  value       = module.rds_postgres.db_instance_endpoint
}

output "postgres_port" {
  description = "RDS PostgreSQL instance port"
  value       = module.rds_postgres.db_instance_port
}

output "postgres_database_name" {
  description = "RDS PostgreSQL database name"
  value       = module.rds_postgres.db_instance_name
}

output "postgres_username" {
  description = "RDS PostgreSQL instance master username"
  value       = module.rds_postgres.db_instance_username
  sensitive   = true
}

output "documentdb_cluster_endpoint" {
  description = "DocumentDB cluster endpoint"
  value       = module.documentdb.cluster_endpoint
}

output "documentdb_cluster_reader_endpoint" {
  description = "DocumentDB cluster reader endpoint"
  value       = module.documentdb.cluster_reader_endpoint
}

output "documentdb_cluster_port" {
  description = "DocumentDB cluster port"
  value       = module.documentdb.cluster_port
}

output "documentdb_cluster_master_username" {
  description = "DocumentDB cluster master username"
  value       = module.documentdb.cluster_master_username
  sensitive   = true
}

# ============================================================================
# ACCESS INFORMATION
# ============================================================================

output "ssh_connection_command" {
  description = "SSH command to connect to bastion host"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${module.bastion.public_ip}"
}

output "web_access_urls" {
  description = "Web access URLs for training system"
  value = {
    training_portal = "http://${module.bastion.public_ip}"
    grafana        = "http://${module.bastion.public_ip}:3000"
    prometheus     = "http://${module.bastion.public_ip}:9090"
    jupyter        = "http://${module.bastion.public_ip}:8888"
    system_monitor = "http://${module.bastion.public_ip}:8080"
  }
}

output "grafana_credentials" {
  description = "Grafana login credentials"
  value = {
    username = "admin"
    password = "dba-training-2024"
    url      = "http://${module.bastion.public_ip}:3000"
  }
  sensitive = true
}

output "jupyter_access" {
  description = "Jupyter notebook access information"
  value = {
    url   = "http://${module.bastion.public_ip}:8888"
    token = "dba-training-2024"
  }
  sensitive = true
}

# ============================================================================
# DATABASE CONNECTION STRINGS
# ============================================================================

output "mysql_connection_string" {
  description = "MySQL connection string"
  value       = "mysql -h ${module.rds_mysql.db_instance_endpoint} -P ${module.rds_mysql.db_instance_port} -u ${module.rds_mysql.db_instance_username} -p ${module.rds_mysql.db_instance_name}"
  sensitive   = true
}

output "postgres_connection_string" {
  description = "PostgreSQL connection string"
  value       = "psql -h ${module.rds_postgres.db_instance_endpoint} -p ${module.rds_postgres.db_instance_port} -U ${module.rds_postgres.db_instance_username} -d ${module.rds_postgres.db_instance_name}"
  sensitive   = true
}

output "mongodb_connection_string" {
  description = "MongoDB connection string"
  value       = "mongosh 'mongodb://${module.documentdb.cluster_master_username}@${module.documentdb.cluster_endpoint}:${module.documentdb.cluster_port}/dba_training_mongodb?ssl=true&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false'"
  sensitive   = true
}

# ============================================================================
# SECURITY GROUP IDS
# ============================================================================

output "security_group_ids" {
  description = "Security group IDs for reference"
  value = {
    bastion              = aws_security_group.bastion.id
    mysql                = aws_security_group.rds_mysql.id
    postgres             = aws_security_group.rds_postgres.id
    documentdb           = aws_security_group.documentdb.id
    student_environments = aws_security_group.student_environments.id
    lambda               = aws_security_group.lambda.id
  }
}

# ============================================================================
# IAM ROLE ARNS
# ============================================================================

output "iam_role_arns" {
  description = "IAM role ARNs for reference"
  value = {
    lambda_execution_role    = aws_iam_role.lambda_execution.arn
    ec2_instance_role        = aws_iam_role.ec2_instance_role.arn
    eventbridge_scheduler    = aws_iam_role.eventbridge_scheduler_role.arn
    backup_role             = aws_iam_role.backup_role.arn
    student_access_role     = aws_iam_role.student_access_role.arn
  }
}

# ============================================================================
# TRAINING SYSTEM STATUS
# ============================================================================

output "training_system_status" {
  description = "Overall training system status and information"
  value = {
    system_name           = var.project_name
    environment          = var.environment
    region               = var.aws_region
    deployment_timestamp = timestamp()
    bastion_ready        = "SSH to ${module.bastion.public_ip} with key ${var.key_name}"
    databases_ready      = "MySQL, PostgreSQL, and DocumentDB clusters deployed"
    monitoring_ready     = "Grafana and Prometheus configured"
    training_scenarios   = length(var.training_scenarios)
    max_concurrent_users = var.max_students
  }
}

# ============================================================================
# COST ESTIMATION
# ============================================================================

output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown (USD)"
  value = {
    bastion_host     = "~$30 (t3.medium)"
    mysql_rds        = "~$15 (db.t3.micro)"
    postgres_rds     = "~$15 (db.t3.micro)"
    documentdb       = "~$50 (db.t3.medium)"
    nat_gateway      = "~$45"
    storage_backup   = "~$10"
    data_transfer    = "~$5"
    total_estimated  = "~$170"
    note            = "Costs may vary based on usage and region"
  }
}

# ============================================================================
# STUDENT QUICK START
# ============================================================================

output "student_quick_start" {
  description = "Quick start information for students"
  value = {
    step_1 = "Access training portal: http://${module.bastion.public_ip}"
    step_2 = "Login to Grafana: http://${module.bastion.public_ip}:3000 (admin/dba-training-2024)"
    step_3 = "Open Jupyter notebooks: http://${module.bastion.public_ip}:8888 (token: dba-training-2024)"
    step_4 = "SSH to bastion: ssh -i ${var.key_name}.pem ec2-user@${module.bastion.public_ip}"
    step_5 = "Run database connection scripts from /opt/dba-training/scripts/"
  }
}

# ============================================================================
# INSTRUCTOR INFORMATION
# ============================================================================

output "instructor_information" {
  description = "Information for instructors managing the system"
  value = {
    ssh_access           = "ssh -i ${var.key_name}.pem ec2-user@${module.bastion.public_ip}"
    service_status_check = "dba-status"
    restart_services     = "dba-start"
    training_directory   = "/opt/dba-training/"
    log_location        = "/opt/dba-training/logs/"
    scenario_count      = length(var.training_scenarios)
    auto_reset_schedule = var.scenario_reset_schedule
  }
}

# ============================================================================
# BACKUP AND RECOVERY
# ============================================================================

output "backup_information" {
  description = "Backup and recovery information"
  value = {
    mysql_backup_window     = var.db_backup_window
    postgres_backup_window  = var.db_backup_window
    documentdb_backup_window = "07:00-09:00"
    retention_period       = "${var.db_backup_retention_period} days"
    automated_snapshots    = var.snapshot_schedule
    cross_region_backup    = var.enable_cross_region_backup
  }
}

# ============================================================================
# TROUBLESHOOTING INFORMATION
# ============================================================================

output "troubleshooting_commands" {
  description = "Common troubleshooting commands"
  value = {
    check_bastion_status    = "ssh -i ${var.key_name}.pem ec2-user@${module.bastion.public_ip} 'sudo systemctl status prometheus grafana-server'"
    view_system_logs       = "ssh -i ${var.key_name}.pem ec2-user@${module.bastion.public_ip} 'sudo journalctl -f'"
    check_database_connectivity = "ssh -i ${var.key_name}.pem ec2-user@${module.bastion.public_ip} '/opt/dba-training/scripts/connect-mysql.sh'"
    restart_monitoring     = "ssh -i ${var.key_name}.pem ec2-user@${module.bastion.public_ip} 'sudo systemctl restart prometheus grafana-server'"
  }
}

# ============================================================================
# DBA TRAINING SYSTEM - TERRAFORM VARIABLES
# ============================================================================
# Variables de configuración para infraestructura de entrenamiento DBA
# Soporta personalización completa del entorno de aprendizaje
# ============================================================================

# ============================================================================
# GENERAL CONFIGURATION
# ============================================================================

variable "project_name" {
  description = "Name of the DBA training project"
  type        = string
  default     = "dba-training-system"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "training"
  
  validation {
    condition     = contains(["dev", "staging", "prod", "training"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, training."
  }
}

variable "owner" {
  description = "Owner of the infrastructure"
  type        = string
  default     = "DBA-Training-Team"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

# ============================================================================
# NETWORK CONFIGURATION
# ============================================================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway"
  type        = bool
  default     = false
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in VPC"
  type        = bool
  default     = true
}

# ============================================================================
# EC2 CONFIGURATION
# ============================================================================

variable "key_name" {
  description = "AWS Key Pair name for EC2 instances"
  type        = string
  default     = "dba-training-key"
}

variable "bastion_instance_type" {
  description = "Instance type for bastion host"
  type        = string
  default     = "t3.medium"
}

variable "student_instance_type" {
  description = "Instance type for student environments"
  type        = string
  default     = "t3.small"
}

variable "max_students" {
  description = "Maximum number of concurrent students"
  type        = number
  default     = 20
  
  validation {
    condition     = var.max_students > 0 && var.max_students <= 100
    error_message = "Max students must be between 1 and 100."
  }
}

# ============================================================================
# DATABASE CONFIGURATION
# ============================================================================

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS instances (GB)"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage for RDS instances (GB)"
  type        = number
  default     = 100
}

variable "db_backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "db_backup_window" {
  description = "Backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "db_maintenance_window" {
  description = "Maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "enable_performance_insights" {
  description = "Enable Performance Insights for RDS"
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period in days"
  type        = number
  default     = 7
}

# ============================================================================
# DOCUMENTDB CONFIGURATION
# ============================================================================

variable "documentdb_cluster_size" {
  description = "Number of instances in DocumentDB cluster"
  type        = number
  default     = 1
}

variable "documentdb_instance_class" {
  description = "DocumentDB instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "documentdb_backup_retention_period" {
  description = "DocumentDB backup retention period"
  type        = number
  default     = 5
}

# ============================================================================
# MONITORING CONFIGURATION
# ============================================================================

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch logs"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring for EC2 instances"
  type        = bool
  default     = true
}

variable "enable_grafana" {
  description = "Enable Grafana dashboard"
  type        = bool
  default     = true
}

variable "enable_prometheus" {
  description = "Enable Prometheus monitoring"
  type        = bool
  default     = true
}

# ============================================================================
# SECURITY CONFIGURATION
# ============================================================================

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access bastion host"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Restrict this in production
}

variable "enable_encryption_at_rest" {
  description = "Enable encryption at rest for databases"
  type        = bool
  default     = true
}

variable "enable_encryption_in_transit" {
  description = "Enable encryption in transit"
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for databases"
  type        = bool
  default     = false  # Set to true for production
}

# ============================================================================
# TRAINING SPECIFIC CONFIGURATION
# ============================================================================

variable "training_scenarios" {
  description = "List of training scenarios to deploy"
  type        = list(string)
  default = [
    "mysql-deadlock",
    "mysql-performance",
    "mysql-replication",
    "mysql-backup-recovery",
    "mysql-connection-exhaustion",
    "postgres-vacuum",
    "postgres-index-bloat",
    "postgres-connection-pooling",
    "postgres-query-optimization",
    "postgres-partition-management",
    "mongodb-sharding",
    "mongodb-replica-set",
    "mongodb-performance",
    "mongodb-aggregation",
    "mongodb-index-optimization"
  ]
}

variable "enable_scenario_automation" {
  description = "Enable automated scenario deployment"
  type        = bool
  default     = true
}

variable "scenario_reset_schedule" {
  description = "Cron schedule for scenario reset (UTC)"
  type        = string
  default     = "0 2 * * *"  # Daily at 2 AM UTC
}

# ============================================================================
# COST OPTIMIZATION
# ============================================================================

variable "enable_spot_instances" {
  description = "Use spot instances for cost optimization"
  type        = bool
  default     = false
}

variable "auto_shutdown_schedule" {
  description = "Auto shutdown schedule for cost savings (UTC)"
  type        = string
  default     = "0 22 * * *"  # Daily at 10 PM UTC
}

variable "auto_startup_schedule" {
  description = "Auto startup schedule (UTC)"
  type        = string
  default     = "0 6 * * 1-5"  # Weekdays at 6 AM UTC
}

variable "enable_auto_scaling" {
  description = "Enable auto scaling for student environments"
  type        = bool
  default     = true
}

# ============================================================================
# BACKUP AND DISASTER RECOVERY
# ============================================================================

variable "enable_cross_region_backup" {
  description = "Enable cross-region backup"
  type        = bool
  default     = false
}

variable "backup_region" {
  description = "Region for cross-region backups"
  type        = string
  default     = "us-west-2"
}

variable "snapshot_schedule" {
  description = "Snapshot schedule for training data"
  type        = string
  default     = "0 1 * * *"  # Daily at 1 AM UTC
}

# ============================================================================
# DEVELOPMENT AND TESTING
# ============================================================================

variable "enable_debug_mode" {
  description = "Enable debug mode with additional logging"
  type        = bool
  default     = false
}

variable "create_test_data" {
  description = "Create test data for scenarios"
  type        = bool
  default     = true
}

variable "enable_scenario_validation" {
  description = "Enable automatic scenario validation"
  type        = bool
  default     = true
}

# ============================================================================
# TAGS
# ============================================================================

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

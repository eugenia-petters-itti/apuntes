# ============================================================================
# DOCUMENTDB MODULE
# ============================================================================
# Módulo para cluster DocumentDB optimizado para entrenamiento DBA
# Incluye configuraciones específicas para escenarios de MongoDB
# ============================================================================

# ============================================================================
# DOCUMENTDB SUBNET GROUP
# ============================================================================

resource "aws_docdb_subnet_group" "main" {
  name       = "${var.name_prefix}-docdb-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-docdb-subnet-group"
    Type = "Database"
  })
}

# ============================================================================
# DOCUMENTDB CLUSTER PARAMETER GROUP
# ============================================================================

resource "aws_docdb_cluster_parameter_group" "main" {
  family      = "docdb5.0"
  name        = "${var.name_prefix}-docdb-cluster-params"
  description = "DocumentDB cluster parameter group for DBA training"

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
    value = "100"
  }

  parameter {
    name  = "ttl_monitor"
    value = "enabled"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-docdb-cluster-params"
    Type = "Database"
  })
}

# ============================================================================
# DOCUMENTDB CLUSTER
# ============================================================================

resource "aws_docdb_cluster" "main" {
  cluster_identifier      = "${var.name_prefix}-docdb-cluster"
  engine                  = "docdb"
  engine_version          = "5.0.0"
  master_username         = var.master_username
  master_password         = var.master_password
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = "07:00-09:00"
  preferred_maintenance_window = "sun:09:00-sun:11:00"
  skip_final_snapshot     = true
  deletion_protection     = var.deletion_protection

  # Network configuration
  db_subnet_group_name   = aws_docdb_subnet_group.main.name
  vpc_security_group_ids = var.security_group_ids

  # Parameter group
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.main.name

  # Security
  storage_encrypted = var.storage_encrypted
  kms_key_id       = var.kms_key_id

  # Logging
  enabled_cloudwatch_logs_exports = ["audit", "profiler"]

  tags = merge(var.tags, {
    Name     = "${var.name_prefix}-docdb-cluster"
    Database = "DocumentDB"
    Type     = "Database"
  })

  depends_on = [
    aws_cloudwatch_log_group.audit,
    aws_cloudwatch_log_group.profiler
  ]
}

# ============================================================================
# DOCUMENTDB CLUSTER INSTANCES
# ============================================================================

resource "aws_docdb_cluster_instance" "cluster_instances" {
  count              = var.cluster_size
  identifier         = "${var.name_prefix}-docdb-${count.index + 1}"
  cluster_identifier = aws_docdb_cluster.main.id
  instance_class     = var.instance_class

  performance_insights_enabled = true

  tags = merge(var.tags, {
    Name     = "${var.name_prefix}-docdb-${count.index + 1}"
    Database = "DocumentDB"
    Type     = "Database"
    Role     = count.index == 0 ? "Primary" : "Secondary"
  })
}

# ============================================================================
# CLOUDWATCH LOG GROUPS
# ============================================================================

resource "aws_cloudwatch_log_group" "audit" {
  name              = "/aws/docdb/${var.name_prefix}/audit"
  retention_in_days = 14

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-docdb-audit-logs"
    Type = "Monitoring"
  })
}

resource "aws_cloudwatch_log_group" "profiler" {
  name              = "/aws/docdb/${var.name_prefix}/profiler"
  retention_in_days = 7

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-docdb-profiler-logs"
    Type = "Monitoring"
  })
}

# ============================================================================
# CLOUDWATCH ALARMS
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  alarm_name          = "${var.name_prefix}-docdb-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/DocDB"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors DocumentDB CPU utilization"
  alarm_actions       = var.alarm_actions

  dimensions = {
    DBClusterIdentifier = aws_docdb_cluster.main.cluster_identifier
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "database_connections" {
  alarm_name          = "${var.name_prefix}-docdb-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/DocDB"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors DocumentDB connections"
  alarm_actions       = var.alarm_actions

  dimensions = {
    DBClusterIdentifier = aws_docdb_cluster.main.cluster_identifier
  }

  tags = var.tags
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "cluster_identifier" {
  description = "DocumentDB cluster identifier"
  value       = aws_docdb_cluster.main.cluster_identifier
}

output "cluster_endpoint" {
  description = "DocumentDB cluster endpoint"
  value       = aws_docdb_cluster.main.endpoint
}

output "cluster_reader_endpoint" {
  description = "DocumentDB cluster reader endpoint"
  value       = aws_docdb_cluster.main.reader_endpoint
}

output "cluster_port" {
  description = "DocumentDB cluster port"
  value       = aws_docdb_cluster.main.port
}

output "cluster_master_username" {
  description = "DocumentDB cluster master username"
  value       = aws_docdb_cluster.main.master_username
}

output "cluster_arn" {
  description = "DocumentDB cluster ARN"
  value       = aws_docdb_cluster.main.arn
}

output "cluster_resource_id" {
  description = "DocumentDB cluster resource ID"
  value       = aws_docdb_cluster.main.cluster_resource_id
}

output "instance_endpoints" {
  description = "DocumentDB instance endpoints"
  value       = aws_docdb_cluster_instance.cluster_instances[*].endpoint
}

output "instance_identifiers" {
  description = "DocumentDB instance identifiers"
  value       = aws_docdb_cluster_instance.cluster_instances[*].identifier
}

# ============================================================================
# DBA TRAINING SYSTEM - TERRAFORM MODULES
# ============================================================================
# Módulos principales para infraestructura de entrenamiento DBA
# Incluye VPC, RDS, DocumentDB, Bastion, y componentes de monitoreo
# ============================================================================

# ============================================================================
# VPC MODULE
# ============================================================================

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.name_prefix}-vpc"
  cidr = local.vpc_cidr

  azs              = local.azs
  public_subnets   = local.public_subnet_cidrs
  private_subnets  = local.private_subnet_cidrs
  database_subnets = local.db_subnet_cidrs

  # NAT Gateway configuration
  enable_nat_gateway = var.enable_nat_gateway
  enable_vpn_gateway = var.enable_vpn_gateway
  single_nat_gateway = false  # Use one NAT gateway per AZ for HA

  # DNS configuration
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  # Database subnet group
  create_database_subnet_group = true
  database_subnet_group_name   = "${local.name_prefix}-db-subnet-group"

  # VPC Flow Logs
  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
    Type = "Network"
  })

  public_subnet_tags = {
    Type = "Public"
    Tier = "Web"
  }

  private_subnet_tags = {
    Type = "Private"
    Tier = "Application"
  }

  database_subnet_tags = {
    Type = "Database"
    Tier = "Data"
  }
}

# ============================================================================
# BASTION HOST MODULE
# ============================================================================

module "bastion" {
  source = "./modules/bastion"

  name_prefix = local.name_prefix
  vpc_id      = module.vpc.vpc_id
  subnet_id   = module.vpc.public_subnets[0]

  instance_type = var.bastion_instance_type
  key_name      = var.key_name
  ami_id        = data.aws_ami.amazon_linux.id

  allowed_cidr_blocks = var.allowed_cidr_blocks

  # Monitoring tools
  enable_grafana    = var.enable_grafana
  enable_prometheus = var.enable_prometheus

  # Database connection info
  mysql_endpoint    = module.rds_mysql.db_instance_endpoint
  postgres_endpoint = module.rds_postgres.db_instance_endpoint
  mongodb_endpoint  = module.documentdb.cluster_endpoint

  tags = local.common_tags
}

# ============================================================================
# RDS MYSQL MODULE
# ============================================================================

module "rds_mysql" {
  source = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "${local.name_prefix}-mysql"

  # Database configuration
  engine               = local.db_configs.mysql.engine
  engine_version       = local.db_configs.mysql.engine_version
  family               = local.db_configs.mysql.family
  major_engine_version = "8.0"
  instance_class       = local.db_configs.mysql.instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_encrypted     = var.enable_encryption_at_rest

  # Database credentials
  db_name  = "dba_training_mysql"
  username = "dba_admin"
  password = random_password.db_passwords["mysql"].result
  port     = local.db_configs.mysql.port

  # Network configuration
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds_mysql.id]

  # Backup configuration
  backup_retention_period = var.db_backup_retention_period
  backup_window          = var.db_backup_window
  maintenance_window     = var.db_maintenance_window

  # Monitoring
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  create_cloudwatch_log_group     = true
  
  performance_insights_enabled          = var.enable_performance_insights
  performance_insights_retention_period = var.performance_insights_retention_period

  # Security
  deletion_protection = var.enable_deletion_protection

  # Parameters for DBA training scenarios
  parameters = [
    {
      name  = "innodb_lock_wait_timeout"
      value = "5"
    },
    {
      name  = "slow_query_log"
      value = "1"
    },
    {
      name  = "long_query_time"
      value = "1"
    },
    {
      name  = "general_log"
      value = "1"
    },
    {
      name  = "max_connections"
      value = "100"
    }
  ]

  tags = merge(local.common_tags, {
    Name     = "${local.name_prefix}-mysql"
    Database = "MySQL"
    Purpose  = "Training"
  })
}

# ============================================================================
# RDS POSTGRESQL MODULE
# ============================================================================

module "rds_postgres" {
  source = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "${local.name_prefix}-postgres"

  # Database configuration
  engine               = local.db_configs.postgres.engine
  engine_version       = local.db_configs.postgres.engine_version
  family               = local.db_configs.postgres.family
  major_engine_version = "15"
  instance_class       = local.db_configs.postgres.instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_encrypted     = var.enable_encryption_at_rest

  # Database credentials
  db_name  = "dba_training_postgres"
  username = "dba_admin"
  password = random_password.db_passwords["postgres"].result
  port     = local.db_configs.postgres.port

  # Network configuration
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds_postgres.id]

  # Backup configuration
  backup_retention_period = var.db_backup_retention_period
  backup_window          = var.db_backup_window
  maintenance_window     = var.db_maintenance_window

  # Monitoring
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = true
  
  performance_insights_enabled          = var.enable_performance_insights
  performance_insights_retention_period = var.performance_insights_retention_period

  # Security
  deletion_protection = var.enable_deletion_protection

  # Parameters for DBA training scenarios
  parameters = [
    {
      name  = "shared_preload_libraries"
      value = "pg_stat_statements"
    },
    {
      name  = "log_statement"
      value = "all"
    },
    {
      name  = "log_min_duration_statement"
      value = "1000"
    },
    {
      name  = "max_connections"
      value = "100"
    },
    {
      name  = "autovacuum"
      value = "on"
    }
  ]

  tags = merge(local.common_tags, {
    Name     = "${local.name_prefix}-postgres"
    Database = "PostgreSQL"
    Purpose  = "Training"
  })
}

# ============================================================================
# DOCUMENTDB MODULE
# ============================================================================

module "documentdb" {
  source = "./modules/documentdb"

  name_prefix = local.name_prefix
  
  # Cluster configuration
  cluster_size     = var.documentdb_cluster_size
  instance_class   = var.documentdb_instance_class
  
  # Credentials
  master_username = "dba_admin"
  master_password = random_password.db_passwords["mongodb"].result
  
  # Network configuration
  subnet_ids         = module.vpc.database_subnets
  security_group_ids = [aws_security_group.documentdb.id]
  
  # Backup configuration
  backup_retention_period = var.documentdb_backup_retention_period
  
  # Security
  storage_encrypted   = var.enable_encryption_at_rest
  deletion_protection = var.enable_deletion_protection
  
  tags = local.common_tags
}

# ============================================================================
# STUDENT ENVIRONMENTS MODULE
# ============================================================================

module "student_environments" {
  source = "./modules/student-environments"

  name_prefix = local.name_prefix
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnets

  instance_type = var.student_instance_type
  key_name      = var.key_name
  ami_id        = data.aws_ami.amazon_linux.id

  max_students = var.max_students
  
  # Training scenarios
  training_scenarios = var.training_scenarios
  
  # Database endpoints
  mysql_endpoint    = module.rds_mysql.db_instance_endpoint
  postgres_endpoint = module.rds_postgres.db_instance_endpoint
  mongodb_endpoint  = module.documentdb.cluster_endpoint
  
  # Auto scaling configuration
  enable_auto_scaling = var.enable_auto_scaling
  
  tags = local.common_tags
}

# ============================================================================
# MONITORING MODULE
# ============================================================================

module "monitoring" {
  source = "./modules/monitoring"

  name_prefix = local.name_prefix
  vpc_id      = module.vpc.vpc_id

  # CloudWatch configuration
  enable_cloudwatch_logs = var.enable_cloudwatch_logs
  log_retention_days     = var.log_retention_days

  # Database monitoring
  mysql_instance_id    = module.rds_mysql.db_instance_identifier
  postgres_instance_id = module.rds_postgres.db_instance_identifier
  documentdb_cluster_id = module.documentdb.cluster_identifier

  # Bastion monitoring
  bastion_instance_id = module.bastion.instance_id

  tags = local.common_tags
}

# ============================================================================
# AUTOMATION MODULE
# ============================================================================

module "automation" {
  source = "./modules/automation"

  name_prefix = local.name_prefix

  # Scenario automation
  enable_scenario_automation = var.enable_scenario_automation
  scenario_reset_schedule    = var.scenario_reset_schedule
  training_scenarios         = var.training_scenarios

  # Cost optimization
  auto_shutdown_schedule = var.auto_shutdown_schedule
  auto_startup_schedule  = var.auto_startup_schedule

  # Backup automation
  snapshot_schedule = var.snapshot_schedule

  # Lambda execution role
  lambda_execution_role_arn = aws_iam_role.lambda_execution.arn

  tags = local.common_tags
}

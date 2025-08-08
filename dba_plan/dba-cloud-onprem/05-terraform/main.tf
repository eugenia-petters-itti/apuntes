# ============================================================================
# DBA CLOUD ONPREM JUNIOR - INFRAESTRUCTURA TERRAFORM PRINCIPAL
# ============================================================================
# Infraestructura completa para programa de entrenamiento DBA
# Soporta 15 escenarios de diagnóstico + enfoque híbrido OnPrem + Cloud
# ============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# ============================================================================
# PROVIDER CONFIGURATION
# ============================================================================

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "DBA-Training-System"
      Environment = var.environment
      Owner       = var.owner
      CreatedBy   = "Terraform"
      Purpose     = "DBA-Education"
    }
  }
}

# ============================================================================
# DATA SOURCES
# ============================================================================

# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get current AWS region
data "aws_region" "current" {}

# ============================================================================
# RANDOM RESOURCES FOR UNIQUE NAMING
# ============================================================================

resource "random_id" "suffix" {
  byte_length = 4
}

resource "random_password" "db_passwords" {
  for_each = toset(["mysql", "postgres", "mongodb"])
  
  length  = 16
  special = true
}

# ============================================================================
# LOCAL VALUES
# ============================================================================

locals {
  # Common naming
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Network configuration
  vpc_cidr = "10.0.0.0/16"
  
  # Availability zones (use first 3)
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
  
  # Subnet CIDRs
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  db_subnet_cidrs      = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
  
  # Database configurations
  db_configs = {
    mysql = {
      engine         = "mysql"
      engine_version = "8.0"
      instance_class = var.db_instance_class
      port          = 3306
      family        = "mysql8.0"
    }
    postgres = {
      engine         = "postgres"
      engine_version = "15.4"
      instance_class = var.db_instance_class
      port          = 5432
      family        = "postgres15"
    }
  }
  
  # Common tags
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner
    CreatedBy   = "Terraform"
    Purpose     = "DBA-Training"
  }
}

# ============================================================================
# OUTPUTS FOR REFERENCE
# ============================================================================

output "infrastructure_summary" {
  description = "Summary of created infrastructure"
  value = {
    vpc_id                = module.vpc.vpc_id
    public_subnet_ids     = module.vpc.public_subnets
    private_subnet_ids    = module.vpc.private_subnets
    database_subnet_ids   = module.vpc.database_subnets
    bastion_public_ip     = module.bastion.public_ip
    bastion_private_ip    = module.bastion.private_ip
    mysql_endpoint        = module.rds_mysql.db_instance_endpoint
    postgres_endpoint     = module.rds_postgres.db_instance_endpoint
    documentdb_endpoint   = module.documentdb.cluster_endpoint
    monitoring_dashboard  = "http://${module.bastion.public_ip}:3000"
    ssh_command          = "ssh -i ${var.key_name}.pem ec2-user@${module.bastion.public_ip}"
  }
}

output "database_credentials" {
  description = "Database connection information"
  sensitive   = true
  value = {
    mysql = {
      endpoint = module.rds_mysql.db_instance_endpoint
      port     = module.rds_mysql.db_instance_port
      username = module.rds_mysql.db_instance_username
      password = random_password.db_passwords["mysql"].result
    }
    postgres = {
      endpoint = module.rds_postgres.db_instance_endpoint
      port     = module.rds_postgres.db_instance_port
      username = module.rds_postgres.db_instance_username
      password = random_password.db_passwords["postgres"].result
    }
    mongodb = {
      endpoint = module.documentdb.cluster_endpoint
      port     = module.documentdb.cluster_port
      username = module.documentdb.cluster_master_username
      password = random_password.db_passwords["mongodb"].result
    }
  }
}

output "student_access_info" {
  description = "Information for students to access the training environment"
  value = {
    bastion_host     = module.bastion.public_ip
    ssh_key_required = var.key_name
    grafana_url      = "http://${module.bastion.public_ip}:3000"
    prometheus_url   = "http://${module.bastion.public_ip}:9090"
    setup_script     = "curl -O https://raw.githubusercontent.com/your-repo/setup-student-env.sh && chmod +x setup-student-env.sh && ./setup-student-env.sh"
  }
}

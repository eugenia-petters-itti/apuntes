# ============================================================================
# DBA TRAINING SYSTEM - SECURITY GROUPS
# ============================================================================
# Grupos de seguridad para todos los componentes del sistema de entrenamiento
# Incluye reglas específicas para bases de datos y acceso de estudiantes
# ============================================================================

# ============================================================================
# BASTION HOST SECURITY GROUP
# ============================================================================

resource "aws_security_group" "bastion" {
  name_prefix = "${local.name_prefix}-bastion-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for DBA training bastion host"

  # SSH access from allowed CIDR blocks
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Grafana access
  ingress {
    description = "Grafana dashboard"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Prometheus access
  ingress {
    description = "Prometheus monitoring"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # HTTP access for training materials
  ingress {
    description = "HTTP access for training materials"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # HTTPS access
  ingress {
    description = "HTTPS access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Jupyter notebook access (for advanced scenarios)
  ingress {
    description = "Jupyter notebook"
    from_port   = 8888
    to_port     = 8888
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # All outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-bastion-sg"
    Type = "Security"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# RDS MYSQL SECURITY GROUP
# ============================================================================

resource "aws_security_group" "rds_mysql" {
  name_prefix = "${local.name_prefix}-mysql-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for MySQL RDS instance"

  # MySQL access from bastion
  ingress {
    description     = "MySQL access from bastion"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # MySQL access from student environments
  ingress {
    description     = "MySQL access from student environments"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.student_environments.id]
  }

  # MySQL access from private subnets (for scenarios)
  ingress {
    description = "MySQL access from private subnets"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = local.private_subnet_cidrs
  }

  tags = merge(local.common_tags, {
    Name     = "${local.name_prefix}-mysql-sg"
    Database = "MySQL"
    Type     = "Security"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# RDS POSTGRESQL SECURITY GROUP
# ============================================================================

resource "aws_security_group" "rds_postgres" {
  name_prefix = "${local.name_prefix}-postgres-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for PostgreSQL RDS instance"

  # PostgreSQL access from bastion
  ingress {
    description     = "PostgreSQL access from bastion"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # PostgreSQL access from student environments
  ingress {
    description     = "PostgreSQL access from student environments"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.student_environments.id]
  }

  # PostgreSQL access from private subnets (for scenarios)
  ingress {
    description = "PostgreSQL access from private subnets"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = local.private_subnet_cidrs
  }

  tags = merge(local.common_tags, {
    Name     = "${local.name_prefix}-postgres-sg"
    Database = "PostgreSQL"
    Type     = "Security"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# DOCUMENTDB SECURITY GROUP
# ============================================================================

resource "aws_security_group" "documentdb" {
  name_prefix = "${local.name_prefix}-documentdb-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for DocumentDB cluster"

  # MongoDB access from bastion
  ingress {
    description     = "MongoDB access from bastion"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # MongoDB access from student environments
  ingress {
    description     = "MongoDB access from student environments"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.student_environments.id]
  }

  # MongoDB access from private subnets (for scenarios)
  ingress {
    description = "MongoDB access from private subnets"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = local.private_subnet_cidrs
  }

  tags = merge(local.common_tags, {
    Name     = "${local.name_prefix}-documentdb-sg"
    Database = "DocumentDB"
    Type     = "Security"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# STUDENT ENVIRONMENTS SECURITY GROUP
# ============================================================================

resource "aws_security_group" "student_environments" {
  name_prefix = "${local.name_prefix}-students-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for student training environments"

  # SSH access from bastion
  ingress {
    description     = "SSH access from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # HTTP access for web-based tools
  ingress {
    description     = "HTTP access from bastion"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # HTTPS access for web-based tools
  ingress {
    description     = "HTTPS access from bastion"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # Custom application ports for training scenarios
  ingress {
    description     = "Custom application ports"
    from_port       = 8000
    to_port         = 8999
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # Inter-student communication for cluster scenarios
  ingress {
    description = "Inter-student communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  # All outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-students-sg"
    Type = "Security"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# LAMBDA FUNCTIONS SECURITY GROUP
# ============================================================================

resource "aws_security_group" "lambda" {
  name_prefix = "${local.name_prefix}-lambda-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for Lambda functions"

  # Database access for automation functions
  egress {
    description     = "MySQL access"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.rds_mysql.id]
  }

  egress {
    description     = "PostgreSQL access"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.rds_postgres.id]
  }

  egress {
    description     = "DocumentDB access"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.documentdb.id]
  }

  # HTTPS for external API calls
  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP for external API calls
  egress {
    description = "HTTP outbound"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-lambda-sg"
    Type = "Security"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# VPC ENDPOINTS SECURITY GROUP
# ============================================================================

resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${local.name_prefix}-vpc-endpoints-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for VPC endpoints"

  # HTTPS access from VPC
  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc-endpoints-sg"
    Type = "Security"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# SECURITY GROUP RULES FOR DATABASE CROSS-ACCESS
# ============================================================================

# Allow MySQL to access PostgreSQL for cross-database scenarios
resource "aws_security_group_rule" "mysql_to_postgres" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds_mysql.id
  security_group_id        = aws_security_group.rds_postgres.id
  description              = "MySQL to PostgreSQL cross-database access"
}

# Allow PostgreSQL to access MySQL for cross-database scenarios
resource "aws_security_group_rule" "postgres_to_mysql" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds_postgres.id
  security_group_id        = aws_security_group.rds_mysql.id
  description              = "PostgreSQL to MySQL cross-database access"
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "security_groups" {
  description = "Security group IDs for reference"
  value = {
    bastion              = aws_security_group.bastion.id
    mysql                = aws_security_group.rds_mysql.id
    postgres             = aws_security_group.rds_postgres.id
    documentdb           = aws_security_group.documentdb.id
    student_environments = aws_security_group.student_environments.id
    lambda               = aws_security_group.lambda.id
    vpc_endpoints        = aws_security_group.vpc_endpoints.id
  }
}

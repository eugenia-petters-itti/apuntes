# ============================================================================
# BASTION HOST MODULE
# ============================================================================
# Módulo para host bastion con herramientas de monitoreo y acceso a bases de datos
# Incluye Grafana, Prometheus y herramientas DBA preinstaladas
# ============================================================================

# ============================================================================
# BASTION HOST INSTANCE
# ============================================================================

resource "aws_instance" "bastion" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name              = var.key_name
  subnet_id             = var.subnet_id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  
  iam_instance_profile = var.iam_instance_profile_name
  
  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    mysql_endpoint    = var.mysql_endpoint
    postgres_endpoint = var.postgres_endpoint
    mongodb_endpoint  = var.mongodb_endpoint
    enable_grafana    = var.enable_grafana
    enable_prometheus = var.enable_prometheus
  }))

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 50
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-bastion"
    Type = "Bastion"
    Role = "Management"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# ELASTIC IP FOR BASTION
# ============================================================================

resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  domain   = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-bastion-eip"
    Type = "Network"
  })

  depends_on = [aws_instance.bastion]
}

# ============================================================================
# SECURITY GROUP FOR BASTION
# ============================================================================

resource "aws_security_group" "bastion" {
  name_prefix = "${var.name_prefix}-bastion-"
  vpc_id      = var.vpc_id
  description = "Security group for DBA training bastion host"

  # SSH access
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Grafana access
  dynamic "ingress" {
    for_each = var.enable_grafana ? [1] : []
    content {
      description = "Grafana dashboard"
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
    }
  }

  # Prometheus access
  dynamic "ingress" {
    for_each = var.enable_prometheus ? [1] : []
    content {
      description = "Prometheus monitoring"
      from_port   = 9090
      to_port     = 9090
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
    }
  }

  # HTTP access for training materials
  ingress {
    description = "HTTP access"
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

  # Jupyter notebook
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

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-bastion-sg"
    Type = "Security"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# CLOUDWATCH LOG GROUP FOR BASTION
# ============================================================================

resource "aws_cloudwatch_log_group" "bastion" {
  name              = "/aws/ec2/${var.name_prefix}-bastion"
  retention_in_days = 14

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-bastion-logs"
    Type = "Monitoring"
  })
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "instance_id" {
  description = "ID of the bastion instance"
  value       = aws_instance.bastion.id
}

output "public_ip" {
  description = "Public IP of the bastion host"
  value       = aws_eip.bastion.public_ip
}

output "private_ip" {
  description = "Private IP of the bastion host"
  value       = aws_instance.bastion.private_ip
}

output "security_group_id" {
  description = "Security group ID of the bastion host"
  value       = aws_security_group.bastion.id
}

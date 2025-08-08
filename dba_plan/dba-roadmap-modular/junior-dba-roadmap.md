# Junior DBA Roadmap (0-2 Years Experience)

## 🎯 Overview
12-month intensive program to build modern DBA foundation with cloud-first approach, automation skills, and Infrastructure as Code competency.

## 📅 Learning Timeline

### Months 1-3: Database Fundamentals + AWS Basics
**Core Database Skills**
- SQL fundamentals (DDL, DML, DCL, TCL)
- Database design principles and normalization
- Basic performance tuning and indexing
- Backup and recovery concepts

**AWS Foundation**
- AWS account setup and IAM basics
- RDS service overview and instance types
- Basic VPC networking for databases
- AWS CLI installation and configuration

**Essential Tools**
- SQL Server Management Studio / pgAdmin
- AWS Console navigation
- Basic command line operations

### Months 4-6: Infrastructure as Code (Terraform)
**Why Terraform First**: 95% of cloud-first companies require IaC skills from day one

**Terraform Basics**
```hcl
# Basic RDS instance creation
resource "aws_db_instance" "main" {
  identifier = "myapp-db"
  engine     = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.micro"
  
  allocated_storage = 20
  storage_type     = "gp2"
  storage_encrypted = true
  
  db_name  = "myapp"
  username = "dbadmin"
  password = var.db_password
  
  vpc_security_group_ids = [aws_security_group.db.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  skip_final_snapshot = false
  final_snapshot_identifier = "myapp-db-final-snapshot"
  
  tags = {
    Environment = "production"
    Team        = "database"
  }
}
```

**Learning Objectives**
- Terraform state management
- Resource dependencies
- Variable usage and validation
- Basic modules creation

### Months 7-9: Python Automation
**Database Automation Scripts**
```python
import boto3
import psycopg2
from datetime import datetime
import logging

class DatabaseMonitor:
    def __init__(self, region='us-east-1'):
        self.rds = boto3.client('rds', region_name=region)
        self.cloudwatch = boto3.client('cloudwatch', region_name=region)
        
    def check_db_connections(self, db_identifier):
        """Monitor database connections"""
        try:
            response = self.cloudwatch.get_metric_statistics(
                Namespace='AWS/RDS',
                MetricName='DatabaseConnections',
                Dimensions=[
                    {'Name': 'DBInstanceIdentifier', 'Value': db_identifier}
                ],
                StartTime=datetime.utcnow() - timedelta(minutes=5),
                EndTime=datetime.utcnow(),
                Period=300,
                Statistics=['Average']
            )
            return response['Datapoints']
        except Exception as e:
            logging.error(f"Error checking connections: {e}")
            return None
```

**Skills Development**
- boto3 AWS SDK usage
- Database connectivity (psycopg2, pymysql)
- Error handling and logging
- Basic monitoring scripts

### Months 10-12: Bash Scripting + Integration
**Operational Scripts**
```bash
#!/bin/bash
# Database backup automation script

DB_IDENTIFIER="myapp-db"
BACKUP_BUCKET="myapp-db-backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Create RDS snapshot
echo "Creating snapshot for $DB_IDENTIFIER..."
aws rds create-db-snapshot \
    --db-instance-identifier $DB_IDENTIFIER \
    --db-snapshot-identifier "${DB_IDENTIFIER}-${DATE}" \
    --region us-east-1

# Wait for snapshot completion
echo "Waiting for snapshot to complete..."
aws rds wait db-snapshot-completed \
    --db-snapshot-identifier "${DB_IDENTIFIER}-${DATE}" \
    --region us-east-1

echo "Backup completed successfully!"
```

**Integration Skills**
- Combining Terraform, Python, and Bash
- CI/CD pipeline basics
- Monitoring and alerting setup
- Documentation and runbooks

## 🎓 Certifications Path

### Priority Order
1. **AWS Cloud Practitioner** (Month 2-3)
   - Foundation certification
   - 2-3 weeks study time
   - Cost: $100

2. **AWS Solutions Architect Associate** (Month 8-10)
   - Core AWS services understanding
   - 6-8 weeks study time
   - Cost: $150

## 📚 Learning Resources

### Books
- "Learning SQL" by Alan Beaulieu
- "Terraform: Up & Running" by Yevgeniy Brikman
- "Automate the Boring Stuff with Python" by Al Sweigart

### Online Courses
- AWS Training and Certification (Free tier)
- Terraform Associate Certification Path
- Python for DevOps (Udemy/Pluralsight)

### Hands-on Projects
1. **Personal Lab Setup**: Create AWS free tier account with basic RDS instance
2. **Terraform Portfolio**: Build 3-5 infrastructure templates
3. **Automation Scripts**: Create monitoring and backup automation
4. **Documentation**: Maintain learning journal and code repository

## 💰 Salary Impact
- **Entry Level**: $65,000 - $75,000 (traditional skills only)
- **With Modern Skills**: $80,000 - $95,000 (25-30% increase)
- **Market Demand**: 300% more job opportunities with automation skills

## ✅ Competency Checklist

### Month 12 Goals
- [ ] Deploy RDS instances using Terraform
- [ ] Write Python scripts for database monitoring
- [ ] Create Bash automation for routine tasks
- [ ] Understand AWS networking for databases
- [ ] Implement basic backup and recovery procedures
- [ ] Document infrastructure and procedures
- [ ] Pass AWS Cloud Practitioner certification

### Ready for Semi-Senior Level When You Can:
- Independently manage small database environments
- Write and maintain Infrastructure as Code
- Automate routine database operations
- Troubleshoot common performance issues
- Collaborate effectively with development teams

---

*Next Step: [Semi-Senior DBA Roadmap](./semi-senior-dba-roadmap.md)*

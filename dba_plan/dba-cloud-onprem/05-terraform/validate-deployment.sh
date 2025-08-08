#!/bin/bash
# ============================================================================
# DBA TRAINING SYSTEM - DEPLOYMENT VALIDATION SCRIPT
# ============================================================================
# Script para validar el despliegue completo de la infraestructura Terraform
# Verifica conectividad, servicios y funcionalidad del sistema de entrenamiento
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/validation-$(date +%Y%m%d-%H%M%S).log"
ERRORS=0

# Functions
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

success() {
    log "${GREEN}✓ $1${NC}"
}

error() {
    log "${RED}✗ $1${NC}"
    ((ERRORS++))
}

warning() {
    log "${YELLOW}⚠ $1${NC}"
}

info() {
    log "${BLUE}ℹ $1${NC}"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        success "$1 is installed"
        return 0
    else
        error "$1 is not installed"
        return 1
    fi
}

# ============================================================================
# HEADER
# ============================================================================

log "============================================================================"
log "🎓 DBA TRAINING SYSTEM - DEPLOYMENT VALIDATION"
log "============================================================================"
log "Timestamp: $(date)"
log "Script: $0"
log "Log file: $LOG_FILE"
log "============================================================================"

# ============================================================================
# PREREQUISITE CHECKS
# ============================================================================

info "Checking prerequisites..."

check_command "terraform"
check_command "aws"
check_command "jq"
check_command "curl"
check_command "ssh"

# Check if we're in the right directory
if [[ ! -f "main.tf" ]]; then
    error "main.tf not found. Please run this script from the terraform directory."
    exit 1
fi

success "All prerequisites met"

# ============================================================================
# TERRAFORM STATE VALIDATION
# ============================================================================

info "Validating Terraform state..."

# Check if terraform is initialized
if [[ ! -d ".terraform" ]]; then
    error "Terraform not initialized. Run 'terraform init' first."
    exit 1
fi

# Check if state file exists
if ! terraform show &> /dev/null; then
    error "No Terraform state found. Run 'terraform apply' first."
    exit 1
fi

success "Terraform state is valid"

# ============================================================================
# EXTRACT INFRASTRUCTURE INFORMATION
# ============================================================================

info "Extracting infrastructure information..."

# Get outputs
if ! BASTION_IP=$(terraform output -raw bastion_public_ip 2>/dev/null); then
    error "Could not get bastion public IP from Terraform output"
    exit 1
fi

if ! VPC_ID=$(terraform output -raw vpc_id 2>/dev/null); then
    error "Could not get VPC ID from Terraform output"
    exit 1
fi

if ! MYSQL_ENDPOINT=$(terraform output -raw mysql_endpoint 2>/dev/null); then
    error "Could not get MySQL endpoint from Terraform output"
    exit 1
fi

if ! POSTGRES_ENDPOINT=$(terraform output -raw postgres_endpoint 2>/dev/null); then
    error "Could not get PostgreSQL endpoint from Terraform output"
    exit 1
fi

if ! DOCUMENTDB_ENDPOINT=$(terraform output -raw documentdb_cluster_endpoint 2>/dev/null); then
    error "Could not get DocumentDB endpoint from Terraform output"
    exit 1
fi

success "Infrastructure information extracted"
info "Bastion IP: $BASTION_IP"
info "VPC ID: $VPC_ID"

# ============================================================================
# AWS RESOURCE VALIDATION
# ============================================================================

info "Validating AWS resources..."

# Check VPC exists
if aws ec2 describe-vpcs --vpc-ids "$VPC_ID" &> /dev/null; then
    success "VPC $VPC_ID exists"
else
    error "VPC $VPC_ID not found"
fi

# Check bastion instance
BASTION_INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=ip-address,Values=$BASTION_IP" "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text 2>/dev/null)

if [[ "$BASTION_INSTANCE_ID" != "None" && "$BASTION_INSTANCE_ID" != "" ]]; then
    success "Bastion instance $BASTION_INSTANCE_ID is running"
else
    error "Bastion instance not found or not running"
fi

# Check RDS instances
if aws rds describe-db-instances --query 'DBInstances[?contains(DBInstanceIdentifier, `mysql`)]' | jq -e '.[0]' &> /dev/null; then
    success "MySQL RDS instance exists"
else
    error "MySQL RDS instance not found"
fi

if aws rds describe-db-instances --query 'DBInstances[?contains(DBInstanceIdentifier, `postgres`)]' | jq -e '.[0]' &> /dev/null; then
    success "PostgreSQL RDS instance exists"
else
    error "PostgreSQL RDS instance not found"
fi

# Check DocumentDB cluster
if aws docdb describe-db-clusters --query 'DBClusters[?contains(DBClusterIdentifier, `docdb`)]' | jq -e '.[0]' &> /dev/null; then
    success "DocumentDB cluster exists"
else
    error "DocumentDB cluster not found"
fi

# ============================================================================
# NETWORK CONNECTIVITY TESTS
# ============================================================================

info "Testing network connectivity..."

# Test SSH connectivity to bastion
if timeout 10 ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o BatchMode=yes \
    -i ~/.ssh/id_rsa ec2-user@"$BASTION_IP" exit 2>/dev/null; then
    success "SSH connectivity to bastion host working"
    SSH_WORKING=true
else
    warning "SSH connectivity test failed (this is normal if key is not in default location)"
    SSH_WORKING=false
fi

# Test HTTP connectivity
if curl -s --connect-timeout 10 "http://$BASTION_IP" > /dev/null; then
    success "HTTP connectivity to bastion host working"
else
    warning "HTTP connectivity test failed (services might still be starting)"
fi

# Test specific service ports
SERVICES=("3000:Grafana" "9090:Prometheus" "8888:Jupyter")
for service in "${SERVICES[@]}"; do
    port="${service%%:*}"
    name="${service##*:}"
    
    if timeout 5 bash -c "</dev/tcp/$BASTION_IP/$port" 2>/dev/null; then
        success "$name service port $port is accessible"
    else
        warning "$name service port $port is not accessible (might still be starting)"
    fi
done

# ============================================================================
# SERVICE VALIDATION (if SSH works)
# ============================================================================

if [[ "$SSH_WORKING" == "true" ]]; then
    info "Validating services on bastion host..."
    
    # Check system services
    SYSTEM_SERVICES=("prometheus" "grafana-server" "node_exporter" "jupyter" "httpd")
    for service in "${SYSTEM_SERVICES[@]}"; do
        if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
            ec2-user@"$BASTION_IP" "sudo systemctl is-active $service" &> /dev/null; then
            success "$service is running"
        else
            warning "$service is not running or not installed"
        fi
    done
    
    # Check DBA training directory structure
    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
        ec2-user@"$BASTION_IP" "test -d /opt/dba-training" &> /dev/null; then
        success "DBA training directory exists"
        
        # Check subdirectories
        SUBDIRS=("scripts" "datasets" "scenarios" "tools" "logs")
        for subdir in "${SUBDIRS[@]}"; do
            if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
                ec2-user@"$BASTION_IP" "test -d /opt/dba-training/$subdir" &> /dev/null; then
                success "DBA training $subdir directory exists"
            else
                warning "DBA training $subdir directory missing"
            fi
        done
    else
        error "DBA training directory not found"
    fi
    
    # Check database connection scripts
    DB_SCRIPTS=("connect-mysql.sh" "connect-postgres.sh" "connect-mongodb.sh")
    for script in "${DB_SCRIPTS[@]}"; do
        if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
            ec2-user@"$BASTION_IP" "test -x /opt/dba-training/scripts/$script" &> /dev/null; then
            success "Database connection script $script exists and is executable"
        else
            warning "Database connection script $script missing or not executable"
        fi
    done
    
else
    warning "Skipping service validation due to SSH connectivity issues"
fi

# ============================================================================
# DATABASE CONNECTIVITY TESTS
# ============================================================================

info "Testing database connectivity..."

# Test MySQL connectivity
if timeout 10 bash -c "</dev/tcp/${MYSQL_ENDPOINT%:*}/${MYSQL_ENDPOINT##*:}" 2>/dev/null; then
    success "MySQL endpoint is reachable"
else
    error "MySQL endpoint is not reachable"
fi

# Test PostgreSQL connectivity
if timeout 10 bash -c "</dev/tcp/${POSTGRES_ENDPOINT%:*}/${POSTGRES_ENDPOINT##*:}" 2>/dev/null; then
    success "PostgreSQL endpoint is reachable"
else
    error "PostgreSQL endpoint is not reachable"
fi

# Test DocumentDB connectivity
if timeout 10 bash -c "</dev/tcp/${DOCUMENTDB_ENDPOINT%:*}/27017" 2>/dev/null; then
    success "DocumentDB endpoint is reachable"
else
    error "DocumentDB endpoint is not reachable"
fi

# ============================================================================
# MONITORING AND ALERTING VALIDATION
# ============================================================================

info "Validating monitoring and alerting..."

# Check CloudWatch log groups
LOG_GROUPS=("/aws/ec2/dba-training" "/aws/rds/instance" "/aws/docdb")
for log_group in "${LOG_GROUPS[@]}"; do
    if aws logs describe-log-groups --log-group-name-prefix "$log_group" | jq -e '.logGroups[0]' &> /dev/null; then
        success "CloudWatch log group $log_group exists"
    else
        warning "CloudWatch log group $log_group not found"
    fi
done

# Check CloudWatch alarms
if aws cloudwatch describe-alarms --alarm-name-prefix "dba-training" | jq -e '.MetricAlarms[0]' &> /dev/null; then
    success "CloudWatch alarms are configured"
else
    warning "No CloudWatch alarms found"
fi

# ============================================================================
# SECURITY VALIDATION
# ============================================================================

info "Validating security configuration..."

# Check security groups
SECURITY_GROUPS=$(aws ec2 describe-security-groups \
    --filters "Name=tag:Project,Values=dba-training-system" \
    --query 'SecurityGroups[].GroupId' \
    --output text)

if [[ -n "$SECURITY_GROUPS" ]]; then
    success "Security groups are configured"
    for sg in $SECURITY_GROUPS; do
        info "Security group: $sg"
    done
else
    error "No security groups found"
fi

# Check IAM roles
IAM_ROLES=$(aws iam list-roles --query 'Roles[?contains(RoleName, `dba-training`)].RoleName' --output text)
if [[ -n "$IAM_ROLES" ]]; then
    success "IAM roles are configured"
    for role in $IAM_ROLES; do
        info "IAM role: $role"
    done
else
    warning "No IAM roles found"
fi

# ============================================================================
# COST OPTIMIZATION CHECKS
# ============================================================================

info "Checking cost optimization settings..."

# Check if instances are using appropriate sizes
INSTANCE_TYPES=$(aws ec2 describe-instances \
    --filters "Name=tag:Project,Values=dba-training-system" "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].InstanceType' \
    --output text)

if [[ -n "$INSTANCE_TYPES" ]]; then
    success "Instance types: $INSTANCE_TYPES"
    for instance_type in $INSTANCE_TYPES; do
        if [[ "$instance_type" =~ ^t3\.(micro|small|medium)$ ]]; then
            success "Instance type $instance_type is cost-optimized"
        else
            warning "Instance type $instance_type might be oversized for training"
        fi
    done
else
    warning "No running instances found"
fi

# ============================================================================
# TRAINING SCENARIO VALIDATION
# ============================================================================

info "Validating training scenarios..."

if [[ "$SSH_WORKING" == "true" ]]; then
    # Check if scenario files exist
    SCENARIO_COUNT=$(ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
        ec2-user@"$BASTION_IP" "find /opt/dba-training/scenarios -name '*.md' 2>/dev/null | wc -l" 2>/dev/null || echo "0")
    
    if [[ "$SCENARIO_COUNT" -gt 0 ]]; then
        success "$SCENARIO_COUNT training scenarios found"
    else
        warning "No training scenario files found"
    fi
else
    warning "Cannot validate training scenarios without SSH access"
fi

# ============================================================================
# PERFORMANCE BASELINE
# ============================================================================

info "Establishing performance baseline..."

# Test response times
if command -v curl &> /dev/null; then
    RESPONSE_TIME=$(curl -o /dev/null -s -w '%{time_total}' "http://$BASTION_IP" 2>/dev/null || echo "timeout")
    if [[ "$RESPONSE_TIME" != "timeout" ]]; then
        success "HTTP response time: ${RESPONSE_TIME}s"
        if (( $(echo "$RESPONSE_TIME < 5.0" | bc -l) )); then
            success "Response time is acceptable"
        else
            warning "Response time is slow (>5s)"
        fi
    else
        warning "Could not measure HTTP response time"
    fi
fi

# ============================================================================
# FINAL REPORT
# ============================================================================

log "============================================================================"
log "🎯 VALIDATION SUMMARY"
log "============================================================================"

if [[ $ERRORS -eq 0 ]]; then
    success "All critical validations passed! ✨"
    log ""
    log "🚀 Your DBA Training System is ready for use!"
    log ""
    log "📋 Quick Access Information:"
    log "   • Training Portal: http://$BASTION_IP"
    log "   • Grafana Dashboard: http://$BASTION_IP:3000 (admin/dba-training-2024)"
    log "   • Prometheus Metrics: http://$BASTION_IP:9090"
    log "   • Jupyter Notebooks: http://$BASTION_IP:8888 (token: dba-training-2024)"
    log "   • SSH Access: ssh -i your-key.pem ec2-user@$BASTION_IP"
    log ""
    log "📚 Next Steps:"
    log "   1. Access the training portal to verify all services"
    log "   2. Test database connections using the provided scripts"
    log "   3. Review the 15 diagnostic scenarios in /opt/dba-training/scenarios/"
    log "   4. Configure student access and begin training sessions"
    log ""
    EXIT_CODE=0
else
    error "$ERRORS validation errors found"
    log ""
    log "🔧 Please review the errors above and:"
    log "   1. Check AWS resource status in the console"
    log "   2. Verify Terraform state with 'terraform plan'"
    log "   3. Review CloudWatch logs for service startup issues"
    log "   4. Ensure security groups allow required traffic"
    log ""
    log "📞 For troubleshooting, check:"
    log "   • Deployment guide: DEPLOYMENT-GUIDE.md"
    log "   • System logs: /var/log/user-data.log on bastion host"
    log "   • Service status: systemctl status <service-name>"
    log ""
    EXIT_CODE=1
fi

log "============================================================================"
log "Validation completed at $(date)"
log "Log file saved: $LOG_FILE"
log "============================================================================"

exit $EXIT_CODE

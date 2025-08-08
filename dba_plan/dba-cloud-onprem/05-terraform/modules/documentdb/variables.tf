# ============================================================================
# DOCUMENTDB MODULE VARIABLES
# ============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "cluster_size" {
  description = "Number of instances in the DocumentDB cluster"
  type        = number
  default     = 1
  
  validation {
    condition     = var.cluster_size >= 1 && var.cluster_size <= 16
    error_message = "Cluster size must be between 1 and 16."
  }
}

variable "instance_class" {
  description = "Instance class for DocumentDB instances"
  type        = string
  default     = "db.t3.medium"
}

variable "master_username" {
  description = "Master username for DocumentDB cluster"
  type        = string
  default     = "dba_admin"
}

variable "master_password" {
  description = "Master password for DocumentDB cluster"
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  description = "List of subnet IDs for DocumentDB subnet group"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for DocumentDB cluster"
  type        = list(string)
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 5
  
  validation {
    condition     = var.backup_retention_period >= 1 && var.backup_retention_period <= 35
    error_message = "Backup retention period must be between 1 and 35 days."
  }
}

variable "storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm triggers"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

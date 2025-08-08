#!/bin/bash

# Backup and Restore Script for MySQL
# Usage: ./backup-restore.sh [backup|restore] [file]

set -e

DB_HOST=${DB_HOST:-mysql-db}
DB_USER=${DB_USER:-app_user}
DB_PASS=${DB_PASS:-app_pass}
DB_NAME=${DB_NAME:-training_db}

backup() {
    local backup_file="/backup/manual_backup_$(date +%Y%m%d_%H%M%S).sql"
    echo "Creating backup: $backup_file"
    
    mysqldump \
        --host="$DB_HOST" \
        --user="$DB_USER" \
        --password="$DB_PASS" \
        --single-transaction \
        --routines \
        --triggers \
        --flush-logs \
        --master-data=2 \
        "$DB_NAME" > "$backup_file"
    
    echo "Backup completed: $backup_file"
}

restore() {
    local backup_file="$1"
    
    if [[ ! -f "$backup_file" ]]; then
        echo "Error: Backup file not found: $backup_file"
        exit 1
    fi
    
    echo "Restoring from: $backup_file"
    
    mysql \
        --host="$DB_HOST" \
        --user="$DB_USER" \
        --password="$DB_PASS" \
        "$DB_NAME" < "$backup_file"
    
    echo "Restore completed"
}

case "$1" in
    backup)
        backup
        ;;
    restore)
        restore "$2"
        ;;
    *)
        echo "Usage: $0 [backup|restore] [file]"
        exit 1
        ;;
esac

#!/bin/bash
# ============================================================================
# MYSQL DEADLOCK MONITORING SCRIPT
# ============================================================================
# Monitors MySQL for deadlock conditions and provides real-time analysis
# Usage: ./deadlock_monitor.sh [options]
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
MYSQL_HOST="${MYSQL_HOST:-localhost}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASS="${MYSQL_PASS:-}"
MYSQL_DB="${MYSQL_DB:-}"

MONITOR_INTERVAL="${MONITOR_INTERVAL:-5}"
LOG_FILE="${LOG_FILE:-/tmp/mysql_deadlock_monitor.log}"
ALERT_THRESHOLD="${ALERT_THRESHOLD:-5}"

# Functions
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
    log_message "SUCCESS: $1"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    log_message "ERROR: $1"
}

warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
    log_message "WARNING: $1"
}

info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
    log_message "INFO: $1"
}

alert() {
    echo -e "${PURPLE}🚨 ALERT: $1${NC}"
    log_message "ALERT: $1"
}

# MySQL connection function
mysql_query() {
    local query="$1"
    local format="${2:-table}"
    
    if [ -n "$MYSQL_PASS" ]; then
        mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" \
              ${MYSQL_DB:+-D "$MYSQL_DB"} -e "$query" --${format} 2>/dev/null
    else
        mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" \
              ${MYSQL_DB:+-D "$MYSQL_DB"} -e "$query" --${format} 2>/dev/null
    fi
}

# Test MySQL connection
test_connection() {
    info "Testing MySQL connection to $MYSQL_HOST:$MYSQL_PORT..."
    
    if mysql_query "SELECT 1" silent >/dev/null 2>&1; then
        success "Connected to MySQL successfully"
        return 0
    else
        error "Cannot connect to MySQL"
        return 1
    fi
}

# Get deadlock statistics
get_deadlock_stats() {
    local stats=$(mysql_query "
        SELECT 
            VARIABLE_NAME,
            VARIABLE_VALUE
        FROM performance_schema.global_status 
        WHERE VARIABLE_NAME IN (
            'Innodb_deadlocks',
            'Innodb_row_lock_waits',
            'Innodb_row_lock_time',
            'Innodb_row_lock_time_avg'
        )
        ORDER BY VARIABLE_NAME
    " silent)
    
    echo "$stats"
}

# Get current lock waits
get_current_lock_waits() {
    local lock_waits=$(mysql_query "
        SELECT 
            r.trx_id as waiting_trx,
            r.trx_mysql_thread_id as waiting_thread,
            SUBSTRING(r.trx_query, 1, 50) as waiting_query,
            b.trx_id as blocking_trx,
            b.trx_mysql_thread_id as blocking_thread,
            SUBSTRING(b.trx_query, 1, 50) as blocking_query,
            l.lock_table as locked_table,
            l.lock_mode as lock_mode
        FROM information_schema.innodb_lock_waits w
        JOIN information_schema.innodb_trx r ON r.trx_id = w.requesting_trx_id
        JOIN information_schema.innodb_trx b ON b.trx_id = w.blocking_trx_id
        JOIN information_schema.innodb_locks l ON l.lock_trx_id = w.blocking_trx_id
    " silent 2>/dev/null)
    
    echo "$lock_waits"
}

# Get active transactions
get_active_transactions() {
    local transactions=$(mysql_query "
        SELECT 
            trx_id,
            trx_state,
            TIMESTAMPDIFF(SECOND, trx_started, NOW()) as duration_sec,
            trx_mysql_thread_id as thread_id,
            trx_tables_locked,
            trx_rows_locked,
            SUBSTRING(trx_query, 1, 60) as current_query
        FROM information_schema.innodb_trx
        ORDER BY trx_started
    " silent 2>/dev/null)
    
    echo "$transactions"
}

# Get connection summary
get_connection_summary() {
    local summary=$(mysql_query "
        SELECT 
            COUNT(*) as total_connections,
            SUM(CASE WHEN COMMAND != 'Sleep' THEN 1 ELSE 0 END) as active_connections,
            SUM(CASE WHEN COMMAND = 'Sleep' THEN 1 ELSE 0 END) as sleeping_connections,
            MAX(TIME) as longest_running_sec
        FROM information_schema.processlist
    " silent)
    
    echo "$summary"
}

# Display header
display_header() {
    clear
    echo -e "${CYAN}============================================================================${NC}"
    echo -e "${CYAN}                    MYSQL DEADLOCK MONITOR${NC}"
    echo -e "${CYAN}============================================================================${NC}"
    echo -e "${BLUE}Host: $MYSQL_HOST:$MYSQL_PORT${NC}"
    echo -e "${BLUE}User: $MYSQL_USER${NC}"
    echo -e "${BLUE}Monitor Interval: ${MONITOR_INTERVAL}s${NC}"
    echo -e "${BLUE}Current Time: $(date)${NC}"
    echo -e "${CYAN}============================================================================${NC}"
    echo ""
}

# Display deadlock statistics
display_deadlock_stats() {
    echo -e "${YELLOW}📊 DEADLOCK STATISTICS${NC}"
    echo "----------------------------------------"
    
    local stats=$(get_deadlock_stats)
    if [ -n "$stats" ]; then
        echo "$stats" | while IFS=$'\t' read -r name value; do
            case "$name" in
                "Innodb_deadlocks")
                    if [ "$value" -gt "$ALERT_THRESHOLD" ]; then
                        echo -e "${RED}  Deadlocks: $value (⚠️  HIGH)${NC}"
                    else
                        echo -e "${GREEN}  Deadlocks: $value${NC}"
                    fi
                    ;;
                "Innodb_row_lock_waits")
                    echo -e "${BLUE}  Row Lock Waits: $value${NC}"
                    ;;
                "Innodb_row_lock_time")
                    echo -e "${BLUE}  Row Lock Time (ms): $value${NC}"
                    ;;
                "Innodb_row_lock_time_avg")
                    echo -e "${BLUE}  Avg Lock Time (ms): $value${NC}"
                    ;;
            esac
        done
    else
        warning "Could not retrieve deadlock statistics"
    fi
    echo ""
}

# Display current lock waits
display_lock_waits() {
    echo -e "${YELLOW}🔒 CURRENT LOCK WAITS${NC}"
    echo "----------------------------------------"
    
    local lock_waits=$(get_current_lock_waits)
    if [ -n "$lock_waits" ]; then
        alert "DEADLOCK SITUATION DETECTED!"
        echo "$lock_waits" | while IFS=$'\t' read -r waiting_trx waiting_thread waiting_query blocking_trx blocking_thread blocking_query locked_table lock_mode; do
            echo -e "${RED}  Waiting Transaction: $waiting_trx (Thread: $waiting_thread)${NC}"
            echo -e "${RED}    Query: $waiting_query${NC}"
            echo -e "${RED}  Blocking Transaction: $blocking_trx (Thread: $blocking_thread)${NC}"
            echo -e "${RED}    Query: $blocking_query${NC}"
            echo -e "${RED}  Table: $locked_table, Mode: $lock_mode${NC}"
            echo "  ----------------------------------------"
        done
    else
        success "No lock waits detected"
    fi
    echo ""
}

# Display active transactions
display_active_transactions() {
    echo -e "${YELLOW}🔄 ACTIVE TRANSACTIONS${NC}"
    echo "----------------------------------------"
    
    local transactions=$(get_active_transactions)
    if [ -n "$transactions" ]; then
        local count=0
        echo "$transactions" | while IFS=$'\t' read -r trx_id state duration thread_id tables_locked rows_locked query; do
            ((count++))
            if [ "$duration" -gt 30 ]; then
                echo -e "${RED}  Transaction $trx_id (Thread: $thread_id) - LONG RUNNING${NC}"
                echo -e "${RED}    Duration: ${duration}s, State: $state${NC}"
                echo -e "${RED}    Tables Locked: $tables_locked, Rows Locked: $rows_locked${NC}"
                echo -e "${RED}    Query: $query${NC}"
            else
                echo -e "${GREEN}  Transaction $trx_id (Thread: $thread_id)${NC}"
                echo -e "${GREEN}    Duration: ${duration}s, State: $state${NC}"
                echo -e "${GREEN}    Tables Locked: $tables_locked, Rows Locked: $rows_locked${NC}"
                echo -e "${GREEN}    Query: $query${NC}"
            fi
            echo "  ----------------------------------------"
        done
        
        if [ "$count" -eq 0 ]; then
            success "No active transactions"
        fi
    else
        success "No active transactions"
    fi
    echo ""
}

# Display connection summary
display_connection_summary() {
    echo -e "${YELLOW}🔗 CONNECTION SUMMARY${NC}"
    echo "----------------------------------------"
    
    local summary=$(get_connection_summary)
    if [ -n "$summary" ]; then
        echo "$summary" | while IFS=$'\t' read -r total active sleeping longest; do
            echo -e "${BLUE}  Total Connections: $total${NC}"
            echo -e "${BLUE}  Active Connections: $active${NC}"
            echo -e "${BLUE}  Sleeping Connections: $sleeping${NC}"
            if [ "$longest" -gt 300 ]; then
                echo -e "${RED}  Longest Running Query: ${longest}s (⚠️  LONG)${NC}"
            else
                echo -e "${GREEN}  Longest Running Query: ${longest}s${NC}"
            fi
        done
    else
        warning "Could not retrieve connection summary"
    fi
    echo ""
}

# Display recommendations
display_recommendations() {
    echo -e "${YELLOW}💡 RECOMMENDATIONS${NC}"
    echo "----------------------------------------"
    
    # Check for high deadlock count
    local deadlock_count=$(mysql_query "SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Innodb_deadlocks'" silent | tail -1)
    
    if [ "$deadlock_count" -gt "$ALERT_THRESHOLD" ]; then
        echo -e "${RED}  • High deadlock count detected ($deadlock_count)${NC}"
        echo -e "${YELLOW}    - Review transaction logic and table access order${NC}"
        echo -e "${YELLOW}    - Consider reducing transaction scope${NC}"
        echo -e "${YELLOW}    - Implement retry logic in application${NC}"
    fi
    
    # Check for long-running transactions
    local long_trx=$(mysql_query "SELECT COUNT(*) FROM information_schema.innodb_trx WHERE TIMESTAMPDIFF(SECOND, trx_started, NOW()) > 30" silent | tail -1)
    
    if [ "$long_trx" -gt 0 ]; then
        echo -e "${RED}  • Long-running transactions detected ($long_trx)${NC}"
        echo -e "${YELLOW}    - Review and optimize slow queries${NC}"
        echo -e "${YELLOW}    - Consider breaking large transactions into smaller ones${NC}"
    fi
    
    # Check connection usage
    local max_connections=$(mysql_query "SELECT @@max_connections" silent | tail -1)
    local current_connections=$(mysql_query "SELECT COUNT(*) FROM information_schema.processlist" silent | tail -1)
    local usage_percent=$((current_connections * 100 / max_connections))
    
    if [ "$usage_percent" -gt 80 ]; then
        echo -e "${RED}  • High connection usage: $usage_percent% ($current_connections/$max_connections)${NC}"
        echo -e "${YELLOW}    - Consider connection pooling${NC}"
        echo -e "${YELLOW}    - Review application connection management${NC}"
    fi
    
    echo ""
}

# Main monitoring loop
monitor_loop() {
    local iteration=0
    
    while true; do
        ((iteration++))
        
        display_header
        echo -e "${CYAN}Iteration: $iteration${NC}"
        echo ""
        
        display_deadlock_stats
        display_lock_waits
        display_active_transactions
        display_connection_summary
        display_recommendations
        
        echo -e "${CYAN}============================================================================${NC}"
        echo -e "${BLUE}Next update in ${MONITOR_INTERVAL} seconds... (Ctrl+C to stop)${NC}"
        
        sleep "$MONITOR_INTERVAL"
    done
}

# Show usage
show_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --host HOST        MySQL host (default: localhost)"
    echo "  -P, --port PORT        MySQL port (default: 3306)"
    echo "  -u, --user USER        MySQL user (default: root)"
    echo "  -p, --password PASS    MySQL password"
    echo "  -d, --database DB      MySQL database"
    echo "  -i, --interval SEC     Monitor interval in seconds (default: 5)"
    echo "  -l, --log FILE         Log file path (default: /tmp/mysql_deadlock_monitor.log)"
    echo "  -t, --threshold NUM    Alert threshold for deadlocks (default: 5)"
    echo "  --help                 Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PASS, MYSQL_DB"
    echo "  MONITOR_INTERVAL, LOG_FILE, ALERT_THRESHOLD"
    echo ""
    echo "Examples:"
    echo "  $0 -h localhost -u root -p mypass"
    echo "  $0 --host mysql-server --user dba_user --interval 10"
    echo "  MYSQL_HOST=db.example.com MYSQL_USER=monitor $0"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--host)
            MYSQL_HOST="$2"
            shift 2
            ;;
        -P|--port)
            MYSQL_PORT="$2"
            shift 2
            ;;
        -u|--user)
            MYSQL_USER="$2"
            shift 2
            ;;
        -p|--password)
            MYSQL_PASS="$2"
            shift 2
            ;;
        -d|--database)
            MYSQL_DB="$2"
            shift 2
            ;;
        -i|--interval)
            MONITOR_INTERVAL="$2"
            shift 2
            ;;
        -l|--log)
            LOG_FILE="$2"
            shift 2
            ;;
        -t|--threshold)
            ALERT_THRESHOLD="$2"
            shift 2
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    echo -e "${CYAN}Starting MySQL Deadlock Monitor...${NC}"
    
    # Test connection
    if ! test_connection; then
        error "Cannot establish MySQL connection. Please check your credentials and connection parameters."
        echo ""
        show_usage
        exit 1
    fi
    
    # Create log file
    touch "$LOG_FILE"
    log_message "MySQL Deadlock Monitor started"
    log_message "Configuration: Host=$MYSQL_HOST:$MYSQL_PORT, User=$MYSQL_USER, Interval=${MONITOR_INTERVAL}s"
    
    # Start monitoring
    trap 'echo -e "\n${YELLOW}Monitoring stopped by user${NC}"; log_message "Monitoring stopped by user"; exit 0' INT
    
    monitor_loop
}

# Execute main function
main "$@"

-- ============================================================================
-- MYSQL DIAGNOSTIC QUERIES - COMPREHENSIVE COLLECTION
-- ============================================================================
-- Collection of essential MySQL diagnostic queries for DBA training
-- Use: mysql -u root -p < mysql-diagnostics.sql
-- ============================================================================

-- Set session variables for better output
SET SESSION sql_mode = '';
SET SESSION group_concat_max_len = 10000;

SELECT '============================================================================' as '';
SELECT 'MYSQL DIAGNOSTIC QUERIES - COMPREHENSIVE ANALYSIS' as '';
SELECT '============================================================================' as '';
SELECT CONCAT('Analysis Date: ', NOW()) as '';
SELECT CONCAT('MySQL Version: ', VERSION()) as '';
SELECT '============================================================================' as '';

-- ============================================================================
-- 1. DEADLOCK ANALYSIS
-- ============================================================================

SELECT '' as '';
SELECT '1. DEADLOCK ANALYSIS' as 'SECTION';
SELECT '===================' as '';

-- Current deadlock statistics
SELECT 
    'Deadlock Statistics' as 'Metric Category',
    VARIABLE_NAME as 'Metric',
    VARIABLE_VALUE as 'Value'
FROM performance_schema.global_status 
WHERE VARIABLE_NAME IN (
    'Innodb_deadlocks',
    'Innodb_row_lock_waits',
    'Innodb_row_lock_time',
    'Innodb_row_lock_time_avg',
    'Innodb_row_lock_time_max'
)
ORDER BY VARIABLE_NAME;

-- Lock wait configuration
SELECT 
    'Lock Configuration' as 'Metric Category',
    VARIABLE_NAME as 'Setting',
    VARIABLE_VALUE as 'Value'
FROM performance_schema.global_variables 
WHERE VARIABLE_NAME IN (
    'innodb_lock_wait_timeout',
    'innodb_deadlock_detect',
    'innodb_print_all_deadlocks',
    'innodb_rollback_on_timeout',
    'transaction_isolation'
)
ORDER BY VARIABLE_NAME;

-- Current lock waits (if any)
SELECT 
    'Current Lock Waits' as 'Analysis',
    r.trx_id as 'Waiting Transaction',
    r.trx_mysql_thread_id as 'Thread ID',
    r.trx_query as 'Waiting Query',
    b.trx_id as 'Blocking Transaction',
    b.trx_mysql_thread_id as 'Blocking Thread ID',
    b.trx_query as 'Blocking Query',
    l.lock_table as 'Locked Table',
    l.lock_mode as 'Lock Mode',
    l.lock_type as 'Lock Type'
FROM information_schema.innodb_lock_waits w
JOIN information_schema.innodb_trx r ON r.trx_id = w.requesting_trx_id
JOIN information_schema.innodb_trx b ON b.trx_id = w.blocking_trx_id
JOIN information_schema.innodb_locks l ON l.lock_trx_id = w.blocking_trx_id;

-- ============================================================================
-- 2. TRANSACTION ANALYSIS
-- ============================================================================

SELECT '' as '';
SELECT '2. TRANSACTION ANALYSIS' as 'SECTION';
SELECT '========================' as '';

-- Current running transactions
SELECT 
    trx_id as 'Transaction ID',
    trx_state as 'State',
    trx_started as 'Started',
    TIMESTAMPDIFF(SECOND, trx_started, NOW()) as 'Duration (seconds)',
    trx_mysql_thread_id as 'Thread ID',
    trx_query as 'Current Query',
    trx_tables_locked as 'Tables Locked',
    trx_rows_locked as 'Rows Locked',
    trx_rows_modified as 'Rows Modified'
FROM information_schema.innodb_trx
ORDER BY trx_started;

-- Transaction isolation levels
SELECT 
    'Transaction Isolation' as 'Category',
    @@global.transaction_isolation as 'Global Level',
    @@session.transaction_isolation as 'Session Level';

-- ============================================================================
-- 3. CONNECTION ANALYSIS
-- ============================================================================

SELECT '' as '';
SELECT '3. CONNECTION ANALYSIS' as 'SECTION';
SELECT '======================' as '';

-- Current connections summary
SELECT 
    'Connection Summary' as 'Category',
    COUNT(*) as 'Total Connections',
    SUM(CASE WHEN COMMAND != 'Sleep' THEN 1 ELSE 0 END) as 'Active Connections',
    SUM(CASE WHEN COMMAND = 'Sleep' THEN 1 ELSE 0 END) as 'Sleeping Connections',
    MAX(TIME) as 'Longest Running (seconds)'
FROM information_schema.processlist;

-- Connection details
SELECT 
    ID as 'Process ID',
    USER as 'User',
    HOST as 'Host',
    DB as 'Database',
    COMMAND as 'Command',
    TIME as 'Time (seconds)',
    STATE as 'State',
    LEFT(INFO, 100) as 'Query (first 100 chars)'
FROM information_schema.processlist
WHERE COMMAND != 'Sleep'
ORDER BY TIME DESC
LIMIT 20;

-- Connection statistics
SELECT 
    'Connection Statistics' as 'Category',
    VARIABLE_NAME as 'Metric',
    VARIABLE_VALUE as 'Value'
FROM performance_schema.global_status 
WHERE VARIABLE_NAME IN (
    'Connections',
    'Max_used_connections',
    'Threads_connected',
    'Threads_running',
    'Aborted_connects',
    'Aborted_clients'
)
ORDER BY VARIABLE_NAME;

-- ============================================================================
-- 4. PERFORMANCE ANALYSIS
-- ============================================================================

SELECT '' as '';
SELECT '4. PERFORMANCE ANALYSIS' as 'SECTION';
SELECT '========================' as '';

-- Query performance summary
SELECT 
    'Query Performance' as 'Category',
    VARIABLE_NAME as 'Metric',
    VARIABLE_VALUE as 'Value'
FROM performance_schema.global_status 
WHERE VARIABLE_NAME IN (
    'Queries',
    'Questions',
    'Slow_queries',
    'Select_scan',
    'Select_full_join',
    'Sort_merge_passes',
    'Created_tmp_tables',
    'Created_tmp_disk_tables'
)
ORDER BY VARIABLE_NAME;

-- InnoDB buffer pool statistics
SELECT 
    'InnoDB Buffer Pool' as 'Category',
    VARIABLE_NAME as 'Metric',
    VARIABLE_VALUE as 'Value'
FROM performance_schema.global_status 
WHERE VARIABLE_NAME LIKE 'Innodb_buffer_pool%'
   AND VARIABLE_NAME IN (
       'Innodb_buffer_pool_pages_total',
       'Innodb_buffer_pool_pages_free',
       'Innodb_buffer_pool_pages_data',
       'Innodb_buffer_pool_pages_dirty',
       'Innodb_buffer_pool_read_requests',
       'Innodb_buffer_pool_reads'
   )
ORDER BY VARIABLE_NAME;

-- Top queries by execution count (if performance_schema enabled)
SELECT 
    'Top Queries by Count' as 'Analysis',
    COUNT_STAR as 'Executions',
    ROUND(AVG_TIMER_WAIT/1000000000, 3) as 'Avg Duration (sec)',
    ROUND(SUM_TIMER_WAIT/1000000000, 3) as 'Total Duration (sec)',
    LEFT(DIGEST_TEXT, 100) as 'Query Pattern'
FROM performance_schema.events_statements_summary_by_digest
WHERE DIGEST_TEXT IS NOT NULL
ORDER BY COUNT_STAR DESC
LIMIT 10;

-- ============================================================================
-- 5. TABLE AND INDEX ANALYSIS
-- ============================================================================

SELECT '' as '';
SELECT '5. TABLE AND INDEX ANALYSIS' as 'SECTION';
SELECT '============================' as '';

-- Table sizes and row counts
SELECT 
    'Table Statistics' as 'Analysis',
    TABLE_SCHEMA as 'Database',
    TABLE_NAME as 'Table',
    ENGINE as 'Engine',
    TABLE_ROWS as 'Estimated Rows',
    ROUND(DATA_LENGTH/1024/1024, 2) as 'Data Size (MB)',
    ROUND(INDEX_LENGTH/1024/1024, 2) as 'Index Size (MB)',
    ROUND((DATA_LENGTH + INDEX_LENGTH)/1024/1024, 2) as 'Total Size (MB)'
FROM information_schema.tables
WHERE TABLE_SCHEMA NOT IN ('information_schema', 'mysql', 'performance_schema', 'sys')
ORDER BY (DATA_LENGTH + INDEX_LENGTH) DESC
LIMIT 20;

-- Index usage statistics
SELECT 
    'Index Usage' as 'Analysis',
    OBJECT_SCHEMA as 'Database',
    OBJECT_NAME as 'Table',
    INDEX_NAME as 'Index',
    COUNT_FETCH as 'Fetches',
    COUNT_INSERT as 'Inserts',
    COUNT_UPDATE as 'Updates',
    COUNT_DELETE as 'Deletes'
FROM performance_schema.table_io_waits_summary_by_index_usage
WHERE OBJECT_SCHEMA NOT IN ('information_schema', 'mysql', 'performance_schema', 'sys')
  AND COUNT_FETCH > 0
ORDER BY COUNT_FETCH DESC
LIMIT 20;

-- ============================================================================
-- 6. REPLICATION STATUS (if applicable)
-- ============================================================================

SELECT '' as '';
SELECT '6. REPLICATION STATUS' as 'SECTION';
SELECT '=====================' as '';

-- Master status
SELECT 'Master Status' as 'Category';
SHOW MASTER STATUS;

-- Slave status (if this is a slave)
SELECT 'Slave Status' as 'Category';
SHOW SLAVE STATUS\G

-- Binary log status
SELECT 
    'Binary Log Configuration' as 'Category',
    VARIABLE_NAME as 'Setting',
    VARIABLE_VALUE as 'Value'
FROM performance_schema.global_variables 
WHERE VARIABLE_NAME IN (
    'log_bin',
    'binlog_format',
    'sync_binlog',
    'expire_logs_days',
    'max_binlog_size'
)
ORDER BY VARIABLE_NAME;

-- ============================================================================
-- 7. ERROR AND WARNING ANALYSIS
-- ============================================================================

SELECT '' as '';
SELECT '7. ERROR AND WARNING ANALYSIS' as 'SECTION';
SELECT '==============================' as '';

-- Error statistics
SELECT 
    'Error Statistics' as 'Category',
    VARIABLE_NAME as 'Error Type',
    VARIABLE_VALUE as 'Count'
FROM performance_schema.global_status 
WHERE VARIABLE_NAME LIKE '%error%'
   OR VARIABLE_NAME LIKE '%abort%'
   OR VARIABLE_NAME LIKE '%denied%'
ORDER BY CAST(VARIABLE_VALUE AS UNSIGNED) DESC;

-- Recent errors from error log (if accessible)
SELECT 'Recent Errors' as 'Analysis';
SELECT 'Check error log file for recent errors and warnings' as 'Recommendation';

-- ============================================================================
-- 8. SYSTEM RESOURCE USAGE
-- ============================================================================

SELECT '' as '';
SELECT '8. SYSTEM RESOURCE USAGE' as 'SECTION';
SELECT '=========================' as '';

-- Memory usage
SELECT 
    'Memory Usage' as 'Category',
    VARIABLE_NAME as 'Memory Component',
    VARIABLE_VALUE as 'Size'
FROM performance_schema.global_variables 
WHERE VARIABLE_NAME IN (
    'innodb_buffer_pool_size',
    'key_buffer_size',
    'query_cache_size',
    'sort_buffer_size',
    'join_buffer_size',
    'read_buffer_size',
    'read_rnd_buffer_size'
)
ORDER BY VARIABLE_NAME;

-- File I/O statistics
SELECT 
    'File I/O Statistics' as 'Category',
    VARIABLE_NAME as 'Metric',
    VARIABLE_VALUE as 'Value'
FROM performance_schema.global_status 
WHERE VARIABLE_NAME IN (
    'Innodb_data_reads',
    'Innodb_data_writes',
    'Innodb_data_read',
    'Innodb_data_written',
    'Innodb_os_log_written'
)
ORDER BY VARIABLE_NAME;

-- ============================================================================
-- 9. RECOMMENDATIONS
-- ============================================================================

SELECT '' as '';
SELECT '9. DIAGNOSTIC RECOMMENDATIONS' as 'SECTION';
SELECT '==============================' as '';

-- Deadlock recommendations
SELECT 'Deadlock Prevention' as 'Category', 
       'Always access tables in the same order' as 'Recommendation'
UNION ALL
SELECT 'Deadlock Prevention', 'Keep transactions short and fast'
UNION ALL
SELECT 'Deadlock Prevention', 'Use appropriate isolation levels'
UNION ALL
SELECT 'Deadlock Prevention', 'Consider using SELECT ... FOR UPDATE sparingly'
UNION ALL
SELECT 'Performance Tuning', 'Monitor buffer pool hit ratio (should be > 95%)'
UNION ALL
SELECT 'Performance Tuning', 'Check for full table scans and optimize queries'
UNION ALL
SELECT 'Performance Tuning', 'Ensure proper indexing on frequently queried columns'
UNION ALL
SELECT 'Monitoring', 'Set up alerts for deadlock occurrences'
UNION ALL
SELECT 'Monitoring', 'Monitor long-running transactions'
UNION ALL
SELECT 'Monitoring', 'Track connection usage and limits';

-- ============================================================================
-- 10. SUMMARY
-- ============================================================================

SELECT '' as '';
SELECT '10. DIAGNOSTIC SUMMARY' as 'SECTION';
SELECT '======================' as '';

SELECT 
    'System Summary' as 'Category',
    CONCAT('MySQL ', VERSION()) as 'Version',
    (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Uptime') as 'Uptime (seconds)',
    (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Threads_connected') as 'Current Connections',
    (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Innodb_deadlocks') as 'Total Deadlocks',
    (SELECT COUNT(*) FROM information_schema.innodb_trx) as 'Active Transactions';

SELECT '============================================================================' as '';
SELECT 'END OF DIAGNOSTIC REPORT' as '';
SELECT CONCAT('Generated at: ', NOW()) as '';
SELECT '============================================================================' as '';

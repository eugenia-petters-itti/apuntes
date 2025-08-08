-- Create application users
CREATE USER IF NOT EXISTS 'app_user'@'%' IDENTIFIED BY 'app_pass';
GRANT SELECT, INSERT, UPDATE, DELETE ON training_db.* TO 'app_user'@'%';

CREATE USER IF NOT EXISTS 'readonly_user'@'%' IDENTIFIED BY 'readonly_pass';
GRANT SELECT ON training_db.* TO 'readonly_user'@'%';

CREATE USER IF NOT EXISTS 'monitor_user'@'%' IDENTIFIED BY 'monitor_pass';
GRANT PROCESS, REPLICATION CLIENT ON *.* TO 'monitor_user'@'%';
GRANT SELECT ON performance_schema.* TO 'monitor_user'@'%';
GRANT SELECT ON information_schema.* TO 'monitor_user'@'%';

FLUSH PRIVILEGES;

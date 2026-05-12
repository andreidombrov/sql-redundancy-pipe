#!/bin/bash

# Configuration (Edit these)
DB_USER="db_user"
DB_PASS="db_pass"
DB_NAME="db_name"
LOCAL_DIR="/local/server/folder/location"
LOG_FILE="/local/path/to/backup.log"
REMOTE_DIR="/remote/server/folder/location"
ID_FILE="/private/ssh/key"
REMOTE_USER="remote_user"
REMOTE_IP="remote_ip"
PORT="remote_port_number"

TIMESTAMP=$(date +%F_%H-%M)
FILENAME="db_backup_$TIMESTAMP.sql.gz"
FULL_PATH="$LOCAL_DIR/$FILENAME"

echo "Backup Started: $(date)"

# Command 1: Create local archive
/usr/bin/mariadb-dump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" | gzip > "$FULL_PATH"
echo "Database dumped to $FILENAME"

# Command 2: Ensure no more than 5 copies locally
ls -t $LOCAL_DIR/db_backup_*.sql.gz | tail -n +6 | xargs --no-run-if-empty rm -f
echo "Local cleanup complete."

# Command 3: Copy to Hostinger
scp -P $PORT -i "$ID_FILE" "$FULL_PATH" $REMOTE_USER@$REMOTE_IP:"$REMOTE_DIR/"
echo "File transferred to Hostinger."

# 4. Keep only the 5 most recent backups on Hostinger
ssh -p $PORT -i $ID_FILE $REMOTE_USER@$REMOTE_IP "ls -t $REMOTE_DIR/db_backup_*.sql.gz | tail -n +6 | xargs --no-run-if-empty rm -f"
echo "Backup cycle complete at $(date) 
------------------------------------------"

# Keep only the last 360 lines of the log file (log is written by the cron job)
echo "$(tail -n 360 $LOG_FILE)" > $LOG_FILE
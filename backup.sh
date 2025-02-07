#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Variables
BACKUP_SOURCE="/etc /home /var/www /bin /usr/bin"
BACKUP_DEST="/backup"
BACKUP_NAME="backup_$(date +%Y%m%d%H%M%S).tar.gz"
REMOTE_SERVER="user@remote.server:/path/to/backup"
LOG_FILE="/var/log/backup.log"

# Create backup destination directory if it doesn't exist
mkdir -p $BACKUP_DEST

# Create the backup
tar -czf $BACKUP_DEST/$BACKUP_NAME $BACKUP_SOURCE

# Check if the backup was successful
if [ $? -eq 0 ]; then
    echo "$(date +%Y-%m-%d\ %H:%M:%S) - Backup created successfully: $BACKUP_DEST/$BACKUP_NAME" >> $LOG_FILE
else
    echo "$(date +%Y-%m-%d\ %H:%M:%S) - Backup failed" >> $LOG_FILE
    exit 1
fi

# Optionally, upload the backup to a remote server
scp $BACKUP_DEST/$BACKUP_NAME $REMOTE_SERVER

# Check if the upload was successful
if [ $? -eq 0 ]; then
    echo "$(date +%Y-%m-%d\ %H:%M:%S) - Backup uploaded successfully to $REMOTE_SERVER" >> $LOG_FILE
else
    echo "$(date +%Y-%m-%d\ %H:%M:%S) - Backup upload failed" >> $LOG_FILE
    exit 1
fi

echo "Backup process completed successfully."

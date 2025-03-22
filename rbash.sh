#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Define the new shell
new_shell="/bin/rbash"

# Check if rbash exists
if ! command -v rbash &> /dev/null; then
    echo "Error: rbash is not installed on this system."
    exit 1
fi

# Initialize log file
log_file="change_shell.log"
> "$log_file"
chmod 600 "$log_file"

# Iterate through all users in /etc/passwd
while IFS=: read -r username _ _ _ _ _ shell; do
    if [[ "$username" != "root" ]]; then
        echo "Changing shell for user: $username to $new_shell" | tee -a "$log_file"
        # Change the user's shell to rbash
        if usermod -s "$new_shell" "$username"; then
            echo "Successfully changed shell for $username to $new_shell" | tee -a "$log_file"
        else
            echo "Failed to change shell for $username" | tee -a "$log_file"
        fi
    fi
done < /etc/passwd

echo "Shell change process completed. Check $log_file for details."

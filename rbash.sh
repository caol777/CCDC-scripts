#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Define the new shell
new_shell="/bin/rbash"

# Check if the system is CentOS 7
if [[ -f /etc/centos-release ]]; then
    echo "Detected CentOS 7."
    # Create rbash as a symbolic link to bash if it doesn't exist
    if [ ! -f "$new_shell" ]; then
        echo "Creating rbash as a symbolic link to bash..."
        ln -s /bin/bash /bin/rbash
        echo "rbash created successfully."
    else
        echo "rbash already exists."
    fi
else
    echo "This script is designed for CentOS 7."
    exit 1
fi

# Initialize log file
log_file="change_shell.log"
> "$log_file"
chmod 600 "$log_file"

# Define a list of predefined users
predefined_users=("joe" "john" "jane" "janecyberstrike" "johncyberstrike" "joecyberstrike")  # Replace with actual usernames

# Iterate through the predefined users
for username in "${predefined_users[@]}"; do
    echo "Changing shell for user: $username to $new_shell" | tee -a "$log_file"
    # Change the user's shell to rbash
    if usermod -s "$new_shell" "$username"; then
        echo "Successfully changed shell for $username to $new_shell" | tee -a "$log_file"
    else
        echo "Failed to change shell for $username" | tee -a "$log_file"
    fi
done

echo "Shell change process completed. Check $log_file for details."

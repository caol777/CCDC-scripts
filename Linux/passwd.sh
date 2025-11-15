#!/bin/bash
# shellcheck disable=SC2016
#
# This script resets the password for all users with a valid login shell.
# It alternates passwords, giving half the users the provided password
# and the other half the *reversed* version of that password.
#
# This is a common script for "blue teams" to secure a system
# at the start of a competition.

set -e

# Read your password from the terminal (with -s to hide it)
read -p "Enter new password: " -s REPLY
echo # Add a newline after the hidden input

# Create the reversed password
REV_REPLY=$(echo "$REPLY" | rev)

echo "Setting passwords and printing user,password list..."
echo "---------------------------------------------------"

# Initialize a counter
i=0

# For users in /etc/passwd with a shell (like /bin/bash or /bin/sh)
# take the username part of the line
for u in $(cat /etc/passwd | grep -E "/bin/.*sh" | cut -d":" -f1); do

    # This 'if' statement checks if the counter 'i' is even or odd
    if [ $((i % 2)) -eq 0 ]; then
        # EVEN: Set the normal password
        PASS_TO_SET="$REPLY"
        
    else
        # ODD: Set the reversed password
        PASS_TO_SET="$REV_REPLY"
    fi

    # Change the password with chpasswd
    echo "$u:$PASS_TO_SET" | chpasswd

    # Print the username and the password that was set
    echo "$u,$PASS_TO_SET"

    # Increment the counter
    i=$((i + 1))

# Terminate the for loop
done

echo "---------------------------------------------------"
echo "Password reset complete."

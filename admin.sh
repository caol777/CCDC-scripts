#!/bin/bash

# List of authorized admin users
admin_users=(
jeremy.rover
maxwell.starling
jack.harris
emily.chen
william.wilson
melissa.chen
john.taylor
laura.harris
alan.chen
anna.wilson
matthew.taylor
)

# Function to check if a user is in the admin list
is_admin_user() {
    local user=$1
    for admin in "${admin_users[@]}"; do
        if [[ "$user" == "$admin" ]]; then
            return 0
        fi
    done
    return 1
}

# Remove unauthorized users from sudo group
for user in $(getent group sudo | awk -F: '{print $4}' | tr ',' ' '); do
    if ! is_admin_user "$user"; then
        echo "Removing user '$user' from sudo group"
        sudo deluser "$user" sudo
    fi
done

# Remove unauthorized users from admin group (if applicable)
for user in $(getent group admin | awk -F: '{print $4}' | tr ',' ' '); do
    if ! is_admin_user "$user"; then
        echo "Removing user '$user' from admin group"
        sudo deluser "$user" admin
    fi
done

# Remove unauthorized users from root group (if applicable)
for user in $(getent group root | awk -F: '{print $4}' | tr ',' ' '); do
    if ! is_admin_user "$user"; then
        echo "Removing user '$user' from root group"
        sudo deluser "$user" root
    fi
done

#!/bin/bash

# ======== PART 1: Remove Unauthorized Users ========
echo "Running unauthorized user removal..."
valid_shells=(/bin/bash /bin/sh /usr/bin/zsh /usr/bin/fish /usr/bin/bash /usr/bin/sh /bin/rbash /usr/bin/rbash)

# List of predefined users (add all authorized users here)
predefined_users=(
seccdc_black postgres root jeremy.rover maxwell.starling jack.harris emily.chen william.wilson
melissa.chen john.taylor laura.harris alan.chen anna.wilson matthew.taylor emily.lee chris.harris
danielle.wilson heather.chen james.taylor ashley.lee mark.wilson rachel.harris alan.taylor
amy.wilson kathleen.chen dave.harris jeff.taylor julie.wilson tom.harris sarah.taylor michael.chen
christine.wilson alan.harris emily.lee tony.taylor tiffany.wilson sharon.harris amy.wilson terry.chen
rachel.wilson tiffany.harris amy.taylor terry.wilson
)

# Critical system users (do not modify or delete these)
critical_system_users=(
root postgres seccdc_black 
)

log_file="userchange.log"
> "$log_file"
chmod 600 "$log_file"

while IFS=: read -r username _ _ _ _ _ shell; do
    echo "Processing user: $username" | tee -a "$log_file"
    # Skip critical system users
    if printf '%s\n' "${critical_system_users[@]}" | grep -qx "$username"; then
        echo "Skipping critical system user: $username" | tee -a "$log_file"
        continue
    fi
    # Check if the user has a valid shell
    if [[ " ${valid_shells[*]} " == *" $shell "* ]]; then
        # Check if the user is not in the predefined list
        if ! printf '%s\n' "${predefined_users[@]}" | grep -qx "$username"; then
            echo "Removing unauthorized user: $username" | tee -a "$log_file"
            # Kill all processes owned by the user
            if pkill -KILL -u "$username"; then
                echo "Successfully killed processes for $username" | tee -a "$log_file"
            else
                echo "No processes found for $username or failed to kill processes" | tee -a "$log_file"
            fi
            # Change shell to nologin
            if usermod -s /usr/sbin/nologin "$username" || usermod -s /sbin/nologin "$username"; then
                echo "Changed shell to nologin for $username" | tee -a "$log_file"
            else
                echo "Failed to change shell for $username" | tee -a "$log_file"
            fi
            # Remove user and home directory
            if userdel -r "$username"; then
                echo "Successfully removed user $username" | tee -a "$log_file"
            else
                echo "Failed to remove user $username" | tee -a "$log_file"
            fi
        fi
    fi
done < /etc/passwd

# ======== PART 2: Change Passwords for Authorized Users ========
echo "Changing passwords for authorized users..."
password_file="user_passwords.txt"
> "$password_file"
chmod 600 "$password_file"

generate_password() {
    tr -dc 'A-Za-z0-9!@#$%^&*()_+{}|:<>?=' < /dev/urandom | head -c 16
}

for user in "${predefined_users[@]}"; do
    if id "$user" &>/dev/null; then
        new_password=$(generate_password)
        if echo "$user:$new_password" | sudo chpasswd; then
            echo "Updated password for $user to $new_password" | tee -a "$password_file"
        else
            echo "Failed to update password for $user" | tee -a "$password_file"
        fi
    else
        echo "User $user not found." | tee -a "$password_file"
    fi
done

# ======== PART 3: Enforce Admin Privileges Only for Authorized Users ========
echo "Enforcing admin privileges..."
admin_users=(
jeremy.rover maxwell.starling jack.harris emily.chen william.wilson melissa.chen
john.taylor laura.harris alan.chen anna.wilson matthew.taylor
)

is_admin_user() {
    local user=$1
    for admin in "${admin_users[@]}"; do
        if [[ "$user" == "$admin" ]]; then
            return 0
        fi
    done
    return 1
}

admin_log="adminchange.log"
> "$admin_log"
chmod 600 "$admin_log"

# Check for both 'sudo' and 'wheel' groups
for group in sudo wheel admin root; do
    if getent group "$group" &>/dev/null; then
        for user in $(getent group "$group" | awk -F: '{print $4}' | tr ',' ' '); do
            if ! is_admin_user "$user"; then
                echo "Removing $user from $group" | tee -a "$admin_log"
                # Use distribution-agnostic command to remove user from group
                if command -v deluser &>/dev/null; then
                    deluser "$user" "$group"
                elif command -v gpasswd &>/dev/null; then
                    gpasswd -d "$user" "$group"
                else
                    echo "Error: Neither deluser nor gpasswd is available. Cannot remove $user from $group." | tee -a "$admin_log"
                fi
            fi
        done
    else
        echo "Group $group not found." | tee -a "$admin_log"
    fi
done

echo "User management script completed."

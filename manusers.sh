#!/bin/bash

# ======== PART 1: Remove Unauthorized Users ========
echo "Running unauthorized user removal..."
valid_shells=(/bin/bash /bin/sh /usr/bin/zsh /usr/bin/fish /usr/bin/bash /usr/bin/sh /bin/rbash /usr/bin/rbash)

predefined_users=(
seccdc_black postgres root jeremy.rover maxwell.starling jack.harris emily.chen william.wilson
melissa.chen john.taylor laura.harris alan.chen anna.wilson matthew.taylor emily.lee chris.harris
danielle.wilson heather.chen james.taylor ashley.lee mark.wilson rachel.harris alan.taylor
amy.wilson kathleen.chen dave.harris jeff.taylor julie.wilson tom.harris sarah.taylor michael.chen
christine.wilson alan.harris emily.lee tony.taylor tiffany.wilson sharon.harris amy.wilson terry.chen
rachel.wilson tiffany.harris amy.taylor terry.wilson
)

log_file="userchange.log"
> "$log_file"
chmod 600 "$log_file"

while IFS=: read -r username _ _ _ _ _ shell; do
    if [[ " ${valid_shells[*]} " == *" $shell "* ]]; then
        if ! printf '%s\n' "${predefined_users[@]}" | grep -qx "$username"; then
            echo "Removing unauthorized user: $username" | tee -a "$log_file"
            pkill -KILL -u "$username"
            usermod -s /usr/sbin/nologin "$username" || usermod -s /sbin/nologin "$username"
            userdel -r "$username"
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
        echo "$user:$new_password" | sudo chpasswd
        echo "Updated password for $user: $new_password" | tee -a "$password_file"
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

for group in sudo admin root; do
    for user in $(getent group "$group" | awk -F: '{print $4}' | tr ',' ' '); do
        if ! is_admin_user "$user"; then
            echo "Removing $user from $group" | tee -a "$admin_log"
            sudo deluser "$user" "$group"
        fi
    done
done

echo "User management script completed."

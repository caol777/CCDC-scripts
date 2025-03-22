#!/bin/bash

# The usage of this script is a repeating loop that ensures the required users exist with admin access.
while true; do
    ###################################################### SCORECHECK USER #################################################
    DONOTTOUCH=(
        blackteam_adm
    )
    ###################################################### SCORECHECK USER #################################################

    ###################################################### Delete users ###################################################
    valid_shells=(/bin/bash /bin/sh /usr/bin/zsh /usr/bin/fish /bin/rbash)

    predefined_users=(
        $1
        $2
        $3
        root
        blackteam_adm
        johncyberstrike 
        joecyberstrike 
        janecyberstrike 
        janicecyberstrike 
        strikesavior 
        planetliberator 
        haunterhunter 
        vanguardprime 
        roguestrike 
        falconpunch 
        specter 
        antiterminite
        joe
        john
        jane
    )

    # Initialize log files
    log_file="userchange.log"
    admin_log="adminchange.log"

    # Create or clear log files and set permissions
    > "$log_file"
    > "$admin_log"
    chmod 600 "$log_file" "$admin_log"

    while IFS=: read -r username _ _ _ _ _ shell; do
        for valid_shell in "${valid_shells[@]}"; do
            if [[ "$shell" == "$valid_shell" ]]; then
                if ! printf '%s\n' "${predefined_users[@]}" | grep -qx "$username"; then
                    echo "User   '$username' is NOT in the predefined list but has a valid shell: $shell" | tee -a "$log_file"
                    pkill --signal SIGKILL -u $username
                    userdel -r $username || deluser $username --remove-home
                    echo "Deleted user '$username'." | tee -a "$log_file"
                fi
                break
            fi
        done
    done < /etc/passwd

    ###################################################### ADMINS #################################################
    administratorGroup=( 
        johncyberstrike 
        joecyberstrike 
        janecyberstrike 
        root
        joe
        john
        jane
    )

    for admin in "${administratorGroup[@]}"; do
        if ! id "$admin" &>/dev/null; then
            useradd -m "$admin"
            echo "User   $admin created." | tee -a "$log_file"
        fi

        # Add user to both sudo and wheel groups
        if ! id "$admin" | grep -qw 'sudo'; then
            usermod -aG sudo "$admin"
            echo "$admin added to sudo group." | tee -a "$admin_log"
        fi

        if ! id "$admin" | grep -qw 'wheel'; then
            usermod -aG wheel "$admin"
            echo "$admin added to wheel group." | tee -a "$admin_log"
        fi
    done

    ###################################################### NORMAL USERS #################################################
    normalUsers=( 
        janicecyberstrike 
        strikesavior 
        planetliberator 
        haunterhunter 
        vanguardprime 
        roguestrike 
        falconpunch 
        specter 
        antiterminite
    )

    ############################## ADDING AND REMOVING ADMINISTRATORS

    echo "###### Ensuring normal users exist and are not part of the sudo group #####"
    for user in "${normalUsers[@]}"; do
        if ! id "$user" &>/dev/null; then
            useradd -m "$user"
            echo "User   $user created." | tee -a "$log_file"
        fi
        if id "$user" | grep -qw 'sudo'; then
            gpasswd -d "$user" sudo
            echo "Removed $user from the sudo group." | tee -a "$admin_log"
        fi
    done

    ###################################################### CHECK WHEEL GROUP #################################################
    echo "Checking users in the wheel group..." | tee -a "$log_file"
    for user in $(getent group wheel | awk -F: '{print $4}' | tr ',' ' '); do
        if ! printf '%s\n' "${predefined_users[@]}" | grep -qx "$user"; then
            echo "Removing $user from the wheel group as they are not in the predefined list." | tee -a "$admin_log"
            gpasswd -d "$user" wheel
        fi
    done

    sleep 30
done

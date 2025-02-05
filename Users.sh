#!/bin/bash
# Goal of this script is to find unauthorized users with a login shell, disable their shell, and delete them.

valid_shells=(/bin/bash /bin/sh /usr/bin/zsh /usr/bin/fish /usr/bin/bash /usr/bin/sh /bin/rbash /usr/bin/rbash)

# List of predefined authorized users
predefined_users=(
seccdc_black
postgres
root
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
emily.lee
chris.harris
danielle.wilson
heather.chen
james.taylor
ashley.lee
mark.wilson
rachel.harris
alan.taylor
amy.wilson
kathleen.chen
dave.harris
jeff.taylor
julie.wilson
tom.harris
sarah.taylor
michael.chen
christine.wilson
alan.harris
emily.lee
tony.taylor
tiffany.wilson
sharon.harris
amy.wilson
terry.chen
rachel.wilson
tiffany.harris
amy.taylor
terry.wilson
)

while IFS=: read -r username _ _ _ _ _ shell; do
    for valid_shell in "${valid_shells[@]}"; do
        if [[ "$shell" == "$valid_shell" ]]; then
            if ! printf '%s\n' "${predefined_users[@]}" | grep -qx "$username"; then
                echo "User '$username' is NOT in the predefined list but has a valid shell: $shell"
                pkill -KILL -u $username
                usermod -s /usr/sbin/nologin $username || usermod -s /sbin/nologin $username
                userdel -r $username
            fi
            break
        fi
    done
done < /etc/passwd

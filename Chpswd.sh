#!/bin/bash

# List of users
users=(
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

# Function to generate a secure password
generate_password() {
    tr -dc 'A-Za-z0-9!@#$%^&*()_+{}|:<>?=' < /dev/urandom | head -c 16
}

# File to save the passwords
password_file="user_passwords.txt"
> "$password_file" # Clear the file if it exists
chmod 600 "$password_file" # Set permissions to be viewable only by root/sudoer

# Change passwords for each user
for user in "${users[@]}"; do
    if id "$user" &>/dev/null; then
        new_password=$(generate_password)
        echo "$user:$new_password" | sudo chpasswd
        echo "Password for user '$user' has been changed to: $new_password" | tee -a "$password_file"
    else
        echo "User '$user' does not exist." | tee -a "$password_file"
    fi
done

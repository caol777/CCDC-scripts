# Read your password from the terminal and store it in $REPLY
read -p "Pw: "

# For users in /etc/passwd with a shell, take the username part of the line
    # NOTE: the format of /etc/passwd looks like this:
        # root:x:0:0:root:/root:/bin/bash
    # So that cut command is saying, take the first field when
    # the line is colon-delimited.
for u in $(cat /etc/passwd | grep -E "/bin/.*sh" | cut -d":" -f1); do

    # Change the password with chpasswd
    echo "$u:$REPLY" | chpasswd

    # Print the password to the terminal
    echo "$u,$REPLY"

# Terminate the for loop
done

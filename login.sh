#!/bin/sh

# Function to count successful and failed login attempts
count_logins() {
  local log_file=$1
  local success_count=0
  local fail_count=0

  if [ -f "$log_file" ]; then
    echo "=========="
    echo "$log_file"
    success_count=$(grep 'Accepted password' "$log_file" | wc -l)
    fail_count=$(grep 'Failed password' "$log_file" | wc -l)
    echo "Successful logins: $success_count"
    echo "Failed logins: $fail_count"
    echo "=========="
  fi
}

# Check and count logins in /var/log/secure
count_logins /var/log/secure

# Check and count logins in /var/log/auth.log
count_logins /var/log/auth.log

# Check and count logins in /var/log/messages
count_logins /var/log/messages

cat /etc/group | grep -E '(sudo|wheel)'

#!/bin/bash

#Make sure tmux is being used first

# Define the .tmux.conf file path
TMUX_CONF="$HOME/.tmux.conf"
TMUX_DIR="$HOME/.tmux"

# Check if tmux is running
if ! tmux has-session 2>/dev/null; then
    echo "No tmux session is running. Please start a tmux session first."
    exit 1
fi

# Create the .tmux directory if it doesn't exist
if [ ! -d "$TMUX_DIR" ]; then
    echo "[+] Creating .tmux directory in home."
    mkdir -p "$TMUX_DIR"
fi

# Check if the bindings already exist
if ! grep -q "bind -n M-1 select-window -t 0" "$TMUX_CONF"; then
    {
        echo "# Key bindings for switching windows and creating new windows"
        echo "bind -n M-1 select-window -t 0"
        echo "bind -n M-2 select-window -t 1"
        echo "bind -n M-3 select-window -t 2"
        echo "bind -n M-4 select-window -t 3"
        echo "bind -n M-5 select-window -t 4"
        echo "bind -n M-6 select-window -t 5"
        echo "bind -n M-7 select-window -t 6"
        echo "bind -n M-8 select-window -t 7"
        echo "bind -n M-9 select-window -t 8"
        echo "bind -n M-g new-window"
    } >> "$TMUX_CONF"
    echo "[+] Key bindings added to $TMUX_CONF and tmux configuration reloaded."
else
    echo "Key bindings already exist in $TMUX_CONF."
fi

# Reload the tmux configuration
tmux source-file "$TMUX_CONF"

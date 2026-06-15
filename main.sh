#!/bin/bash

# ==============================================================================
# GuardianShell Daemon - Main Control Panel
# Sourced from Project Blueprint requirements.
# ==============================================================================

# ------------------------------------------------------------------------------
# ORDINARY (SHELL-LOCAL) VARIABLES
# These variables are only used in the local shell scope and are not inherited
# by child processes or sub-scripts.
# ------------------------------------------------------------------------------
choice=""
script_exit_status=0
config_status="Unloaded"

# ------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Explicitly exported so that sub-scripts (monitor.sh and backup.sh) inherit them.
# ------------------------------------------------------------------------------
export GS_PROJECT_ROOT="/home/vachan/Documents/guardianshell"
export CONFIG_FILE="$GS_PROJECT_ROOT/config/threshold.conf"
export LOG_FILE="$GS_PROJECT_ROOT/logs/system_monitor.log"

# --- Here Document Configuration Generator ---
# Generates a fresh default config/threshold.conf file if missing or requested.
setup_default_config() {
    echo "=========================================================="
    echo "      Generating Default Threshold Configuration          "
    echo "=========================================================="
    
    # Ensure config directory exists
    mkdir -p "$(dirname "$CONFIG_FILE")"
    
    # We use a Here Document (<<) with quoted EOF ('EOF') to prevent
    # early expansion of shell variables like $HOME during creation,
    # ensuring they evaluate dynamically when the file is sourced.
    cat << 'EOF' > "$CONFIG_FILE"
# ==============================================================================
# GuardianShell Threshold Configuration File
# ==============================================================================
# This file defines environment variables used by the monitor and backup scripts.
# Sourced dynamically at startup.

# Maximum disk usage percentage allowed (ordinary integer)
MAX_DISK=80

# Maximum CPU usage percentage allowed (ordinary integer)
MAX_CPU=90

# Swap activity threshold (si/so in KB/s) above which thrashing is warned
THRASH_LIMIT=100

# Base directory to run backups from
BACKUP_SRC="/home/vachan/Documents/guardianshell"

# Target directory to place completed read-only backups
BACKUP_DIR="/home/vachan/Documents/guardianshell/backups"

# Regular expression pattern to search files (defaults to shell, config, and log files)
BACKUP_PATTERN='\.(sh|log|conf)$'

# Maximum failed authentication attempts allowed in last 100 log lines
MAX_AUTH_FAILURES=5

# Location of authentication log file (standard on Ubuntu/Debian)
AUTH_LOG="/var/log/auth.log"
EOF

    echo "✅ Configuration file written to: $CONFIG_FILE"
    echo "=========================================================="
}

# --- Load Configuration ---
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "⚠️  Configuration file not found!"
        setup_default_config
    fi
    
    # Source the threshold.conf file
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
    
    # Export the configured thresholds and paths so child scripts inherit them
    export MAX_DISK
    export MAX_CPU
    export THRASH_LIMIT
    export BACKUP_SRC
    export BACKUP_DIR
    export BACKUP_PATTERN
    export MAX_AUTH_FAILURES
    export AUTH_LOG
    
    config_status="Loaded"
}

# --- Initialize ---
load_config

# ------------------------------------------------------------------------------
# POSITIONAL PARAMETER HANDLING (CLI Arguments)
# Check if positional parameters ($1, $2, etc.) are passed to run directly.
# ------------------------------------------------------------------------------
if [ $# -gt 0 ]; then
    case "$1" in
        -m|--monitor|monitor)
            echo "Direct Action: Running Real-time System Monitor..."
            ./scripts/monitor.sh
            script_exit_status=$?
            echo "Monitor finished with exit status: $script_exit_status"
            exit $script_exit_status
            ;;
        -b|--backup|backup)
            echo "Direct Action: Executing Smart Backup..."
            ./scripts/backup.sh
            script_exit_status=$?
            echo "Backup finished with exit status: $script_exit_status"
            exit $script_exit_status
            ;;
        -s|--setup|setup)
            setup_default_config
            exit 0
            ;;
        -h|--help|help)
            echo "GuardianShell Daemon CLI Utility"
            echo "Usage: $0 [option]"
            echo "Options:"
            echo "  -m, --monitor   Run the system monitor directly"
            echo "  -b, --backup    Run the smart backup directly"
            echo "  -s, --setup     Regenerate default configurations"
            echo "  -h, --help      Show this help information"
            exit 0
            ;;
        *)
            echo "❌ Error: Invalid argument '$1'" >&2
            echo "Usage: $0 [--monitor | --backup | --setup | --help]" >&2
            exit 1
            ;;
    esac
fi

# ------------------------------------------------------------------------------
# INTERACTIVE MENU LOOP
# Runs the interpretive cycle when no CLI arguments are supplied.
# ------------------------------------------------------------------------------
while true; do
    echo ""
    echo "=========================================================="
    echo "          🛡️   GUARDIANSHELL DAEMON MENU   🛡️"
    echo "=========================================================="
    echo "  Config Status : $config_status (MAX_DISK=$MAX_DISK%, MAX_CPU=$MAX_CPU%)"
    echo "  Backup Source : $BACKUP_SRC"
    echo "  Backup Target : $BACKUP_DIR"
    echo "----------------------------------------------------------"
    echo "  1) Run Real-time System Monitor"
    echo "  2) Execute Smart Regex Backup"
    echo "  3) View System Monitor Log"
    echo "  4) Regenerate Threshold Configuration (Here Doc)"
    echo "  5) Exit"
    echo "=========================================================="
    
    # Read user input from stdin (FD 0)
    read -r -p "Select an option [1-5]: " choice
    
    case "$choice" in
        1)
            echo ""
            echo "Starting System Monitor..."
            ./scripts/monitor.sh
            script_exit_status=$?
            echo "----------------------------------------------------------"
            echo "Process exited with status code: $script_exit_status"
            if [ $script_exit_status -eq 0 ]; then
                echo "✅ Check completed: All metrics are within threshold parameters."
            else
                echo "⚠️  Alert: One or more system metrics exceeded critical limits! Checked log file."
            fi
            ;;
        2)
            echo ""
            read -r -p "Enter source directory to scan/backup [default: $BACKUP_SRC]: " user_src
            user_src=${user_src:-$BACKUP_SRC}
            echo "Executing Smart Backup on directory: $user_src..."
            ./scripts/backup.sh "$user_src"
            script_exit_status=$?
            echo "----------------------------------------------------------"
            echo "Process exited with status code: $script_exit_status"
            if [ $script_exit_status -eq 0 ]; then
                echo "✅ Smart Backup completed successfully."
            else
                echo "❌ Backup operation failed. See details above."
            fi
            ;;
        3)
            echo ""
            echo "--- System Monitor Log [Last 15 Entries] ---"
            if [ -f "$LOG_FILE" ]; then
                tail -n 15 "$LOG_FILE"
            else
                echo "ℹ️  No log file found at $LOG_FILE. Exceeded limits generate logs."
            fi
            echo "--------------------------------------------"
            ;;
        4)
            echo ""
            setup_default_config
            load_config
            ;;
        5)
            echo ""
            echo "Exiting GuardianShell Daemon. Secure shell offline."
            exit 0
            ;;
        *)
            echo ""
            echo "❌ Invalid choice! Please select an option between 1 and 5."
            ;;
    esac
    
    # Pause before displaying the menu again
    echo ""
    read -r -p "Press [Enter] to return to the main menu..." _
done

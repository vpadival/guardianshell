#!/bin/bash

# ==============================================================================
# GuardianShell Smart Backup Sub-Script
# Handles file scanning via regex and archiving with secure permissions.
# ==============================================================================

# Sourcing or fallback to environment defaults
BACKUP_SRC=${BACKUP_SRC:-"/home/vachan/Documents/guardianshell"}
BACKUP_DIR=${BACKUP_DIR:-"/home/vachan/Documents/guardianshell/backups"}
BACKUP_PATTERN=${BACKUP_PATTERN:-"\.(sh|log|conf)$"}

# Allow positional parameter $1 to override the source directory
if [ $# -gt 0 ] && [ -n "$1" ]; then
    BACKUP_SRC="$1"
fi

echo "============================================="
echo "        GuardianShell Smart Backup           "
echo "============================================="
echo "Source Directory: $BACKUP_SRC"
echo "Backup Directory: $BACKUP_DIR"
echo "Search Pattern  : $BACKUP_PATTERN"
echo "---------------------------------------------"

# Ensure source directory exists
if [ ! -d "$BACKUP_SRC" ]; then
    echo "❌ Error: Source directory $BACKUP_SRC does not exist!" >&2
    exit 1
fi

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# 1. Use ls -l combined with egrep to find files matching the pattern
echo "Scanning for matching files..."

# We list all files in detail, filter for regular files (starting with '-'),
# and use egrep to match the file pattern at the end of the line.
raw_list=$(ls -l "$BACKUP_SRC" | egrep '^-' | egrep "$BACKUP_PATTERN")

# 2. Count matching files using wc -l
# We define 'backup_count' as an ordinary (local shell) variable.
backup_count=$(echo "$raw_list" | grep -v '^$' | wc -l)

if [ "$backup_count" -eq 0 ]; then
    echo "ℹ️  No files matching the pattern were found in $BACKUP_SRC."
    echo "============================================="
    exit 0
fi

echo "Found $backup_count matching file(s):"
# Format and display the files with sizes
echo "$raw_list" | awk '{print " - " $NF " (" $5 " bytes)"}'

# Extract the filenames (the last column of the ls -l output)
filenames=$(echo "$raw_list" | awk '{print $NF}')

# 3. Create backup archive folder and backup file
timestamp=$(date '+%Y%m%d_%H%M%S')
backup_filename="backup_${timestamp}.tar.gz"
backup_filepath="$BACKUP_DIR/$backup_filename"

echo "---------------------------------------------"
echo "Archiving files to: $backup_filepath"

# Execute tar. We use -C to execute relative to the source directory
# and pass the list of files from standard input using '-T -'
echo "$filenames" | tar -czf "$backup_filepath" -C "$BACKUP_SRC" -T -

# Check the exit status of the backup operation
if [ $? -eq 0 ]; then
    echo "✅ Archive successfully created."
    echo "---------------------------------------------"
    
    # Display initial permissions
    echo "Initial archive permissions:"
    ls -l "$backup_filepath"
    
    # 4. Crucial Syllabus Feature: Permission Modification
    # Make backup files strictly read-only to prevent accidental edits or deletion.
    # Note: We demonstrate two ways here:
    #   - Absolute (Octal) method: chmod 400
    #   - Relative method: chmod a-w or chmod u-w,g-w,o-w
    # We will use the absolute method 'chmod 400' as the primary action.
    
    echo "Applying strict read-only permissions (chmod 400)..."
    chmod 400 "$backup_filepath"
    
    # Display final permissions to verify
    echo "Secure archive permissions:"
    ls -l "$backup_filepath"
    
else
    echo "❌ Error: Archiving failed." >&2
    exit 1
fi

echo "============================================="
exit 0

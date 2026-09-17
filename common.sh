#!/bin/bash

# Colors
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

# Variables
USERID=$(id -u)
LOG_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(basename "$0" .sh)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

# Ensure log folder exists
mkdir -p "$LOG_FOLDER"

# Root user check function
check_root() {
    if [ "$USERID" -ne 0 ]; then
        echo -e "$R Error: Please run the script with root user $N" | tee -a "$LOG_FILE"
        exit 1
    else
        echo "You are running with root access" | tee -a "$LOG_FILE"
    fi
}

# Validation function
VALIDATE() {
    if [ -n "$1" ] && [ "$1" -eq 0 ]; then
        echo -e "$2 .... $G SUCCESS $N" | tee -a "$LOG_FILE"
    else
        echo -e "$2 .... $R FAILURE $N" | tee -a "$LOG_FILE"
        exit 1
    fi
}
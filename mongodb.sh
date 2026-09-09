#!/bin/bash

# ==============================
# COLORS
# ==============================

R="\e[31m"       # Red
G="\e[32m"       # Green
Y="\e[33m"       # Yellow
B="\e[34m"       # Blue
C="\e[36m"       # Cyan
N="\e[0m"        # Reset
BOLD="\e[1m"


# ==============================
# LOG CONFIGURATION
# ==============================

LOG_FOLDER="/var/log/shell-practice"

SCRIPT_NAME=$(basename "$0" .sh)

LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"


# ==============================
# PACKAGES
# ==============================

PACKAGES=("nginx" "mysql" "python3")


# ==============================
# CREATE LOG DIRECTORY
# ==============================

mkdir -p "$LOG_FOLDER"


# ==============================
# CHECK ROOT USER
# ==============================

USERID=$(id -u)

if [ "$USERID" -ne 0 ]
then
    echo -e "${R}${BOLD}ERROR:${N} Please run this script with root user"
    exit 1
else
    echo -e "${G}${BOLD}SUCCESS:${N} Running with root user" | tee -a "$LOG_FILE"

VALIDATE() {

    if [ "$1" -eq 0 ]
    then
        echo -e "${G}${BOLD}SUCCESS:${N} $2 installation completed" | tee -a "$LOG_FILE"
    else
        echo -e "${R}${BOLD}FAILURE:${N} $2 installation failed" | tee -a "$LOG_FILE"
    fi

}

cp mongodb.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
VALIDATE $? "Copying MongoDB repo"

dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE "$?" "mongodb"

systemctl enable mongod &>>$LOG_FILE
VALIDATE "$?" "mongodb enable"

systemctl start mongod &>>$LOG_FILE
VALIDATE "$?" "mongodb start"

sed -i -e 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Editing MongoDB conf file for remote connections"


systemctl restart mongod &>>$LOG_FILE
VALIDATE $? "Restarting MongoDB"
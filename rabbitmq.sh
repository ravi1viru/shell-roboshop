#!/bin/bash

# Colors
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

# Variables
USERID=$(id -u)
LOG_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(basename $0 | cut -d "." -f1)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

# Ensure log folder exists
mkdir -p $LOG_FOLDER
echo "Script starting date: $(date)" | tee -a $LOG_FILE

# Root user check
if [ $USERID -ne 0 ]; then
    echo -e "$R Error: please run the script with root user $N" | tee -a $LOG_FILE
    exit 1
else
    echo "You are running with root access" | tee -a $LOG_FILE
fi

# Validation function
VALIDATE() {
    if [ $1 -eq 0 ]; then
        echo -e "$2 .... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 .... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "copy rabbit mq file"

dnf install rabbitmq-server -y
systemctl enable rabbitmq-server
systemctl start rabbitmq-server
VALIDATE $? "start rabbit mq file"

rabbitmqctl add_user roboshop roboshop123
VALIDATE $? "create a user"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
VALIDATE $? "permissios"

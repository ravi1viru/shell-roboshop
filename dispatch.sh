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

dnf install golang -y
VALIDATE $? "install golang"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Create system user roboshop"
else
    echo -e "System user roboshop already exists ... $Y SKIPPING $N" | tee -a $LOG_FILE
fi

mkdir -p /app
VALIDATE $? "create app directory"

curl -L -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip 
cd /app 
unzip /tmp/dispatch.zip
VALIDATE $? "unzip dispatch file"

cd /app 
go mod init dispatch
go get 
go build
VALIDATE $? "download depencies"

cp $SCRIPT_DIR/dispatch.service /etc/systemd/system/dispatch.service
VALIDATE $? "copy dispatch services"

systemctl daemon-reload
systemctl enable dispatch 
systemctl start dispatch
VALIDATE $? "start dispatch"
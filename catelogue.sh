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

# NodeJS setup
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disable NodeJS default version"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enable NodeJS 20 version"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Install NodeJS 20 version"

# Create roboshop user if not exists
id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Create system user roboshop"
else
    echo -e "System user roboshop already exists ... $Y SKIPPING $N" | tee -a $LOG_FILE
fi

# Create app directory
mkdir -p /app &>>$LOG_FILE
VALIDATE $? "Create /app directory"

# Download and extract catalogue
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Download catalogue component"

cd /app
unzip -o /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Unzip catalogue component"

npm install &>>$LOG_FILE
VALIDATE $? "Install NodeJS dependencies"

# Copy systemd service file
cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOG_FILE
VALIDATE $? "Copy catalogue service file"

# Start service
systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Reload systemd"

systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "Enable catalogue service"

systemctl start catalogue &>>$LOG_FILE
VALIDATE $? "Start catalogue service"

# MongoDB setup
cp $SCRIPT_DIR/mongodb.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
VALIDATE $? "Copy MongoDB repo file"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Install MongoDB client"

mongosh --host mongodb.leardevops.online </app/db/master-data.js &>>$LOG_FILE
VALIDATE $? "Load master data into MongoDB"

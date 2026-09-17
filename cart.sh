#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(basename "$0" .sh)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p "$LOG_FOLDER"
echo "Script starting date: $(date)" | tee -a "$LOG_FILE"

if [ $USERID -ne 0 ]; then
    echo -e "$R Error: Please run the script with root user $N" | tee -a "$LOG_FILE"
    exit 1
else
    echo "You are running with root access" | tee -a "$LOG_FILE"
fi

VALIDATE(){
    if [ $1 -eq 0 ]; then 
        echo -e "$2 ... $G SUCCESS $N" | tee -a "$LOG_FILE"
    else
        echo -e "$2 ... $R FAILURE $N" | tee -a "$LOG_FILE"
        exit 1
    fi
}

dnf module disable nodejs -y &>> "$LOG_FILE"
VALIDATE $? "Disable default Node.js module"

dnf module enable nodejs:20 -y &>> "$LOG_FILE"
VALIDATE $? "Enable Node.js 20 module"

dnf install nodejs -y &>> "$LOG_FILE"
VALIDATE $? "Install Node.js"

id roboshop &>> "$LOG_FILE"
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> "$LOG_FILE"
    VALIDATE $? "Create system user roboshop"
else
    echo -e "System user roboshop already exists ... $Y SKIPPING $N" | tee -a "$LOG_FILE"
fi

mkdir -p /app 
VALIDATE $? "Create /app directory"

rm -rf /app/*
curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>> "$LOG_FILE"
cd /app 
unzip -o /tmp/cart.zip &>> "$LOG_FILE"
VALIDATE $? "Extract cart application code"

npm install &>> "$LOG_FILE"
VALIDATE $? "Install dependencies"

cp "$SCRIPT_DIR/cart.services" /etc/systemd/system/cart.service &>> "$LOG_FILE"
VALIDATE $? "Copy cart service unit file"

systemctl daemon-reload &>> "$LOG_FILE" && \
systemctl enable cart &>> "$LOG_FILE" && \
systemctl start cart &>> "$LOG_FILE"
VALIDATE $? "Start and enable cart service"
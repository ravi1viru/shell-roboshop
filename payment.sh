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
echo "Script starting date: $(date)" | tee -a "$LOG_FILE"

# Root user check
if [ $USERID -ne 0 ]; then
    echo -e "$R Error: please run the script with root user $N" | tee -a "$LOG_FILE"
    exit 1
else
    echo "You are running with root access" | tee -a "$LOG_FILE"
fi

# Validation function
VALIDATE() {
    if [ $1 -eq 0 ]; then
        echo -e "$2 .... $G SUCCESS $N" | tee -a "$LOG_FILE"
    else
        echo -e "$2 .... $R FAILURE $N" | tee -a "$LOG_FILE"
        exit 1
    fi
}

dnf install python3 gcc python3-devel -y &>> "$LOG_FILE"
VALIDATE $? "Install Python, GCC, and Python Header packages"

id roboshop &>> "$LOG_FILE"
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> "$LOG_FILE"
    VALIDATE $? "Create system user roboshop"
else
    echo -e "System user roboshop already exists ... $Y SKIPPING $N" | tee -a "$LOG_FILE"
fi

mkdir -p /app
rm -rf /app/*
curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>> "$LOG_FILE"
cd /app 
unzip -o /tmp/payment.zip &>> "$LOG_FILE"
VALIDATE $? "Extract payment application code"

npm_or_pip_install() {
    cd /app
    pip3 install -r requirements.txt &>> "$LOG_FILE"
}
npm_or_pip_install
VALIDATE $? "Install Python dependencies"

cp "$SCRIPT_DIR/payment.service" /etc/systemd/system/payment.service &>> "$LOG_FILE"
VALIDATE $? "Copy payment systemd service unit file"

systemctl daemon-reload &>> "$LOG_FILE" && \
systemctl enable payment &>> "$LOG_FILE" && \
systemctl start payment &>> "$LOG_FILE"
VALIDATE $? "Start and enable payment service"
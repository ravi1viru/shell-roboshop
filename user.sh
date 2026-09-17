#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOG_FOLDER
echo " script starting date: $(date) " | tee -a $LOG_FILE

if [ $USERID -ne 0 ]
    then
         echo -e "$R Error: please run the script with root user $N" | tee -a $LOG_FILE
         exit 1
    else
         echo " You are running with root access" 
fi

VALIDATE(){

    if [ $1 -eq 0 ]
       then 
           echo -e " $2 is .... $G SUCCESS $N" | tee -a $LOG_FILE
       else
           echo " $2 IS ... $R FAILURE $N" | tee -a $LOG_FILE
           exit 1
    fi
}

dnf module disable nodejs -y
VALIDATE $? "disable nodejs"

dnf module enable nodejs:20 -y
VALIDATE $? "enable nodejs"

dnf install nodejs -y
VALIDATE $? "install nodejs"


id roboshop
if [ $? -ne 0 ]
   then 
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
        echo " create a robosho user" 
    else
         echo "user already add SKIPPED"
fi

mkdir -p /app
VALIDATE $? "make the app directory"

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip 
cd /app 
unzip /tmp/user.zip
VALIDATE $? "unzip the code"

cd /app 
npm install 
VALIDATE $? "install dependiences"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service
VALIDATE $? "copy user service"

systemctl daemon-reload
systemctl enable user 
systemctl start user
VALIDATE $? "start user service"
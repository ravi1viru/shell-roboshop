#!/bin/bash

USERID=$(id u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"

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

dnf module list nginx
VALIDATE $? "list of modulas in nginx"

dnf module disable nginx -y
VALIDATE $? "disable all the modulas in nginx"

dnf module enable nginx:1.24 -y
VALIDATE $? "enable nginx 24"

dnf install nginx -y
VALIDATE $? "install nginx"

systemctl enable nginx 
VALIDATE $? "enable nginx"

systemctl start nginx 
VALIDATE $? "start nginx"


rm -rf /usr/share/nginx/html/*
VALIDATE $? "remove default content in ginx server"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
VALIDATE $? "download the front end content"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip
VALIDATE $? "uzip the front end content"

cp nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "copy nginx content"

systemctl restart nginx 
VALIDATE $? "restart nginx"

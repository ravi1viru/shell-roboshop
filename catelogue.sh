


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

dnf module disable nodejs -y
VALIDATE $? "disable nodejs default version"

dnf module enable nodejs:20 -y
VALIDATE $? "enable nodejs 20 version"

dnf install nodejs -y
VALIDATE $? "install nodejs 20 version"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? " create a systeam user roboshop"

mkdir /app 
VALIDATE $? " create app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
VALIDATE $? " download catelougue component"

cd /app 
unzip /tmp/catalogue.zip
VALIDATE $? " unzip catelougue component"

cd /app 
npm install 
VALIDATE $? " install dependncies"

cp catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? " copy catalogue servives"

systemctl daemon-reload
VALIDATE $? " relod new services"

systemctl enable catalogue 
VALIDATE $? " enable new services"

systemctl start catalogue
VALIDATE $? " start new services"

cp mongodb.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? " coping load the data"

dnf install mongodb-mongosh -y
VALIDATE $? " install mongodb"

mongosh --host mongodb.leardevops.online </app/db/master-data.js
VALIDATE $? " load the master data"
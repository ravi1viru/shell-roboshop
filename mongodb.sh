#!/bin/bash

source ./common.sh
app_name=mongodb

check_root
VALIDATE

cp mongodb.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copig mangodb repo" 

dnf install mongodb-org -y &>>$LOG_FILE 
VALIDATE $? "install mongodb"

systemctl enable mongod  &>>$LOG_FILE
VALIDATE $? "enable mongodb"

systemctl start mongod &>>$LOG_FILE
VALIDATE $? "start mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "give access to all local ports"

systemctl restart mongod &>>$LOG_FILE
VALIDATE $? "restart mongodb"
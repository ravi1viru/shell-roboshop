#!/bin/bash


USERID=$(id -u)
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
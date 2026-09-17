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
VALIDATE $? "enable nodejs 20"

dnf install nodejs -y
VALIDATE $? "install nodejs"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Create system user roboshop"
else
    echo -e "System user roboshop already exists ... $Y SKIPPING $N" | tee -a $LOG_FILE
fi

mkdir -p /app 
VALIDATE $? "create app directory"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip
cd /app 
unzip /tmp/cart.zip
VALIDATE $? "unzip cart"

cd /app 
npm install 
VALIDATE $? "install dependiecies"

cp $SCRIPT_DIR/cart.serivices /etc/systemd/system/cart.service
VALIDATE $? "copy cart services"

systemctl daemon-reload
systemctl enable cart 
systemctl start cart
VALIDATE $? " start services"
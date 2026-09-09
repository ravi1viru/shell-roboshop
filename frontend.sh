```bash
#!/bin/bash

# ==============================
# USER ID
# ==============================

USERID=$(id -u)


# ==============================
# COLORS
# ==============================

R="\e[31m"       # Red
G="\e[32m"       # Green
Y="\e[33m"       # Yellow
N="\e[0m"        # Reset
BOLD="\e[1m"


# ==============================
# LOG CONFIGURATION
# ==============================

LOGS_FOLDER="/var/log/roboshop-logs"

SCRIPT_NAME=$(basename "$0" .sh)

LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

SCRIPT_DIR="$PWD"


# ==============================
# CREATE LOG DIRECTORY
# ==============================

mkdir -p "$LOGS_FOLDER"

echo "Script started executing at: $(date)" | tee -a "$LOG_FILE"


# ==============================
# CHECK ROOT USER
# ==============================

if [ "$USERID" -ne 0 ]
then
    echo -e "${R}${BOLD}ERROR:${N} Please run this script with root access" | tee -a "$LOG_FILE"
    exit 1
else
    echo -e "${G}${BOLD}SUCCESS:${N} You are running with root access" | tee -a "$LOG_FILE"
fi


# ==============================
# VALIDATE FUNCTION
# ==============================

VALIDATE() {

    if [ "$1" -eq 0 ]
    then
        echo -e "$2 is ... ${G}SUCCESS${N}" | tee -a "$LOG_FILE"
    else
        echo -e "$2 is ... ${R}FAILURE${N}" | tee -a "$LOG_FILE"
        exit 1
    fi

}


# ==============================
# DISABLE DEFAULT NGINX MODULE
# ==============================

dnf module disable nginx -y &>> "$LOG_FILE"
VALIDATE $? "Disabling Default Nginx"


# ==============================
# ENABLE NGINX 1.24
# ==============================

dnf module enable nginx:1.24 -y &>> "$LOG_FILE"
VALIDATE $? "Enabling Nginx:1.24"


# ==============================
# INSTALL NGINX
# ==============================

dnf install nginx -y &>> "$LOG_FILE"
VALIDATE $? "Installing Nginx"


# ==============================
# ENABLE NGINX SERVICE
# ==============================

systemctl enable nginx &>> "$LOG_FILE"
VALIDATE $? "Enabling Nginx"


# ==============================
# START NGINX
# ==============================

systemctl start nginx &>> "$LOG_FILE"
VALIDATE $? "Starting Nginx"


# ==============================
# REMOVE DEFAULT WEBSITE CONTENT
# ==============================

rm -rf /usr/share/nginx/html/* &>> "$LOG_FILE"
VALIDATE $? "Removing default content"


# ==============================
# DOWNLOAD FRONTEND
# ==============================

curl -o /tmp/frontend.zip \
https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip \
&>> "$LOG_FILE"

VALIDATE $? "Downloading frontend"


# ==============================
# EXTRACT FRONTEND
# ==============================

cd /usr/share/nginx/html || exit 1

unzip /tmp/frontend.zip &>> "$LOG_FILE"
VALIDATE $? "Unzipping frontend"


# ==============================
# REMOVE DEFAULT NGINX CONFIG
# ==============================

rm -f /etc/nginx/nginx.conf &>> "$LOG_FILE"
VALIDATE $? "Removing default nginx.conf"


# ==============================
# COPY ROBOSHOP NGINX CONFIG
# ==============================

cp "$SCRIPT_DIR/nginx.conf" /etc/nginx/nginx.conf &>> "$LOG_FILE"
VALIDATE $? "Copying nginx.conf"


# ==============================
# TEST NGINX CONFIGURATION
# ==============================

nginx -t &>> "$LOG_FILE"
VALIDATE $? "Testing Nginx configuration"


# ==============================
# RESTART NGINX
# ==============================

systemctl restart nginx &>> "$LOG_FILE"
VALIDATE $? "Restarting Nginx"


# ==============================
# COMPLETED
# ==============================

echo -e "${G}${BOLD}SUCCESS:${N} Frontend setup completed successfully" | tee -a "$LOG_FILE"

echo "Script completed executing at: $(date)" | tee -a "$LOG_FILE"
```

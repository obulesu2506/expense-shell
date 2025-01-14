#!/bin/bash

USERID=$(id -u)
R="\e[31m"
Y="\e[32m"
G="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 .... $R FAILURE $N"
        exit 1 # other than 0
    else
        echo -e "$2 .... $R SUCCESS $N"
    fi
}

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo "ERROR:: you must have SUDO access for executing the script"
        exit 1 #other than 0
    fi
}

mkdir -p $LOGS_FOLDER
echo "Script started to execute at:: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

dnf install nginx -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing nginx"

systemctl enable nginx &>>$LOG_FILE_NAME
VALIDATE $? "Enabling nginx"

systemctl start nginx &>>$LOG_FILE_NAME
VALIDATE $? "STARTING nginx server"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE_NAME
VALIDATE $? "Removing existing version of code"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "Downloading Latest Code"

cd /usr/share/nginx/html
VALIDATE $? "Moving to HTML Directory"

unzip /tmp/frontend.zip &>>$LOG_FILE_NAME
VALIDATE $? "unzipping front end code"

cp /home/ec2-user/expense-shell/expense.conf /etc/nginx/default.d/expense.conf
VALIDATE $? "Copied expense config"

systemctl restart nginx &>>$LOG_FILE_NAME
VALIDATE $? "Restarting nginx"


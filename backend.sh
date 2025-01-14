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
        exit 1 # Other than 0
    else
        echo -e "$2 .... $G SUCCESS $N"
    fi
}

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo "ERROR: You must have SUDO access for executing the script"
        exit 1 # Other than 0 for failure cases
    fi
}

echo "Script started Executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

dnf module disable nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Disabling Existing default NodeJS"

dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
VALIDATE $? "Enabling NodeJS 20 version"

dnf install nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing NodeJS"

id expense &>>$LOG_FILE_NAME
if [ $? -ne 0 ]
then
    useradd expense &>>$LOG_FILE_NAME
    VALIDATE $? "Adding Expense user"
else
    echo -e "expense user already exists .... $Y SKIPPED $N"
fi

mkdir -p /app &>>$LOG_FILE_NAME #Creating directory for installing backend application service
VALIDATE $? "Creating App directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "Downloading backend"

cd /app
rm -rf /app/*  #Deleting old backend version service if anything present

unzip /tmp/backend.zip  &>>$LOG_FILE_NAME
VALIDATE $? "unzip backend"

npm install &>>$LOG_FILE_NAME
VALIDATE $? "Installing Dependencies"

cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service

dnf install mysql -y &>>$LOG_FILE_NAME  #Prepare MYSQL Schema for storing Transactions which will ocme from Frontend(User input)
VALIDATE $? "Installing MYSQL Client"

mysql -h mysql.kumardevops.store -u root -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE_NAME
VALIDATE $? "Setting up the transactions schema & tables"


systemctl daemon-reload &>>$LOG_FILE_NAME
VALIDATE $? "Daemon Reload"

systemctl enable backend &>>$LOG_FILE_NAME
VALIDATE $? "Enabling backend service"

systemctl restart backend &>>$LOG_FILE_NAME
VALIDATE $? "Restarting the Backend"








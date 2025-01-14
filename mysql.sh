#!/bin/bash

USERID=$(id -u)

R="\e[31m"
Y="\e[32m"
G="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/expense-logs"
LOGS_FILE=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 .... $R FAILURE $N"
        exit 1 # Other than 0
    else
        echo -e "$2 .... $R SUCCESS $N"
    fi
}

CHECK_ROOT(){
    if [ $USERID -ne 0]
    then
        echo -e "ERROR: you must have sudo access for executing the script"
        exit 1 # Other than 0
    fi
}

echo "Script started executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

dnf install mysql-server -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing MYSQL Server"

systemctl enable mysqld &>>$LOG_FILE_NAME
VALIDATE $? "Enabling MYSQL Server"

systemctl start mysqld &>>$LOG_FILE_NAME
VALIDATE $? "Starting the MYSQL Server"

mysql -h mysql.kumardevops.store -u root -pExpenseApp@1 -e 'show databases;' &>>$LOG_FILE_NAME

if [ $? -ne 0 ]
then
    echo "MYSQL Root Password Setup not done" &>>$LOG_FILE_NAME
    mysql_secure_installation --set-root-pass ExpenseApp@1
    VALIDATE $? "Setting Root Password"
else
    echo -e "MYSQL Root Password setup alreday done ...... $Y SKIPPING $N" &>>$LOG_FILE_NAME
fi

#!/bin/bash

# Variables
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

# Create log directory
mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

# Check root access
if [ $USERID -ne 0 ]; then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1
else
    echo "You are running with root access" | tee -a $LOG_FILE
fi

# Validation function
VALIDATE(){
    if [ $1 -eq 0 ]; then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

# MongoDB setup
cp mongo.repo /etc/yum.repos.d/mongodb.repo
VALIDATE $? "Copying MongoDB repo"

dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "Installing MongoDB server"

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "Enabling MongoDB service"

systemctl start mongod &>>$LOG_FILE
VALIDATE $? "Starting MongoDB service"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Editing MongoDB config for remote access"

systemctl restart mongod &>>$LOG_FILE
VALIDATE $? "Restarting MongoDB service"

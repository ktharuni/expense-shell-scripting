#!/bin/bash

LOG_DIR="/var/log/expense"
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOG_DIR/$SCRIPT_NAME-$TIMESTAMP.log"

mkdir -p $LOG_DIR

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
N="\e[0m"

CHECK(){
      if [ $USERID -ne 0 ]
      then
         echo "Please check root access privileges" | tee -a $LOG_FILE
         exit 1
      fi
}
VALIDATE(){
        if [ $1 -ne 0 ]
        then
          echo -e "$2 is $R failed $N" | tee -a $LOG_FILE
          exit 1
        else
          echo -e "$2 is $G successful $N" | tee -a $LOG_FILE 
        fi          
}

echo "Script started executing at: $(date)" 

CHECK()

dnf module list nodejs -y &>>$LOG_FILE
VALIDATE $? "Disable default nodejs"

dnf module list nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enable nodejs 20 version"

dnf list installed nodejs &>>$LOG_FILE 
if [ $? -ne 0 ]
then
   echo "nodejs is not yet installed...installing now" 
   dnf install nodejs -y &>>$LOG_FILE
   VALIDATE $? "nodejs installation"
else
   echo "nodejs is already installed"
fi

id expense &>>$LOG_FILE
if [ $? -ne 0 ]
then
   echo "Expense user does not exits...creating now"
   useradd expense &>>$LOG_FILE
   VALIDATE $? "creation of expense user"
else
   echo "expense user is already created"
fi

mkdir -p /app
VALIDATE $? "creating app directory" 

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE 
VALIDATE $? "Downloading backend application"

cd /app
rm -rf /app/*
unzip /tmp/backend.zip
VALIDATE $? "extracting downloaded application in app directory" 

npm install &>>$LOG_FILE
VALIDATE $? "Installing application"
cp /home/ec2-user/expense-shell-scripting/backend.service /etc/systemd/system/backend.service

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing mysql client"

mysql -h 172.31.39.209 -u root -pExpense@1 < /app/schema/backend.sql &>>$LOG_FILE 
VALIDATE $? "connecting to mysql server and schema loading"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon reload"

systemctl enable backend &>>$LOG_FILE
VALIDATE $? "Enabled backend"

systemctl restart backend &>>$LOG_FILE
VALIDATE $? "Restarting backend"


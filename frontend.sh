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

dnf list installed nginx &>>$LOG_FILE
if [ $? -ne 0 ]
then
   echo "nginx is not yet installed...installing now"
   dnf install nginx -y &>>$LOG_FILE
   VALIDATE $? "mysql installation"
else
   echo "nginx is already installed"
fi

systemctl status nginx
if [ $? -ne 0 ]
then
    echo "nginx is not yet started and enabled...start now and enable it" | tee -a $LOG_FILE
    systemctl start nginx &>>$LOG_FILE
    VALIDATE $? "nginx service"  
    systemctl enable nginx &>>$LOG_FILE
    VALIDATE $? "nginx service enabling"
else
   echo "nginx service is already started and enabled" | tee -a $LOG_FILE
fi 

curl -o /tmp/frontend.zip
VALIDATE $? "Downloading frontend application" 

cd /usr/share/nginx/
rm -rf /usr/share/nginx/*
unzip /tmp/frontend.zip
VALIDATE $? "extracting downloaded webpages"

systemctl restart nginx
VALIDATE $? "restarting nginx"
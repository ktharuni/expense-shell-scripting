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
        if [ $? -ne 0 ]
        then
          echo -e "$1 $2 is $R failed $N"
          exit 1
        else
          echo -e "$1 $2 is $G successful $N"  
        fi          
}

echo "Script started executing at: $(date)" 


CHECK()

dnf list installed mysql-server &>>$LOG_FILE 
if [ $? -ne 0 ]
then
   echo "mysql is not yet installed...installing now" | tee -a $LOG_FILE
   dnf install mysql-server -y &>>$LOG_FILE
   VALIDATE mysql installation
else
   echo "mysql is already installed"
fi

systemctl status mysqld
if [ $? -ne 0 ]
then
    echo "mysql service is not yet started and enabled...start now and enable it" | tee -a $LOG_FILE
    systemctl start mysqld 
    VALIDATE mysql service  
    systemctl enable mysqld &>>$LOG_FILE
    VALIDATE mysqlservice enable
else
   echo "mysql service is already started and enabled"
fi 

mysql -h 23.20.161.234 -u root -pExpense@1 -e 'show databases'
if [ $? -ne 0 ]
then
   echo "Password setup is not yet done....setting up password" | tee -a $LOG_FILE
   mysql_secure_installation --set-root-pass pExpense@1 &>>$LOG_FILE
   VALIDATE mysqlpassword setup
else
   echo "mysql password is already setup....skip it"
fi




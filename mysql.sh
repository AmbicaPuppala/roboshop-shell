#!/bin/bash
UserId=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

Log_Folder="/var/log/roboshop-logs"
Log_File=$(echo $0 |cut -d "." -f1)
Timestamp=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$Log_Folder/$Log_File-$Timestamp.log"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
       echo -e "$2 ... $R FAILURE $N"
    else
       echo -e "$2 ...$G SUCCESS $N"
    fi     
}

CHECK_ROOT(){
    if [ $UserId -ne 0 ]
    then
        echo "you must have root user access to execute scipt"
        exit1
    fi
}

echo "script statrted executing at: $Timestamp" &>>LOG_FILE_NAME
CHECK_ROOT

dnf install mysql-server -y &>>LOG_FILE_NAME
VALIDATE $? "Installing Mysql server"

systemctl enable mysqld &>>LOG_FILE_NAME
VALIDATE $? "Enabling Mysql server"

systemctl start mysqld &>>LOG_FILE_NAME
VALIDATE $? "starting Mysql server"

mysql -h mysql.aslearnings.fun -u root -pRoboShop@1 -e 'show databases;'&>>$LOG_FILE_NAME 

if [ $? -ne 0 ]
then
    echo "MySQL Root password not setup" &>>$LOG_FILE_NAME 
    mysql_secure_installation --set-root-pass RoboShop@1 
    VALIDATE $? "setting root password"
else
    echo -e "MySQL Root password already setup ... $Y SKIPPING $N"
fi    






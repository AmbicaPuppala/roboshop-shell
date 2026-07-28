#!/bin/bash
USERID=$(id -u)
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
       echo -e "$2...$R failure $N"
    else
        echo -e "$2...$G success $N"   
    fi    
}

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo "you must have root user access to execute scipt"
        exit1
    fi
}


echo "script started executing at :$Timestamp" &>>LOG_FILE_NAME
CHECK_ROOT


cp /home/ec2-user/roboshop-shell/mongo.repo /etc/yum.repos.d/mongo.repo

dnf install mongodb-org -y &>>LOG_FILE_NAME
VALIDATE $? "installing mongodb"

systemctl enable mongod &>>LOG_FILE_NAME
VALIDATE $? "Enabling mongodb"

systemctl start mongod &>>LOG_FILE_NAME
VALIDATE $? "starting mongodb"

sed -i 's/^bindIp:.*/bindIp: 0.0.0.0/' /etc/mongod.conf

systemctl restart mongod &>>LOG_FILE_NAME
VALIDATE $? "restarts mongodb service" 


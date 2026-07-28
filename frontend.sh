#!/bin/bash
USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

Log_Folder="/var/log/roboshop-logs"
Log_File=$(echo $0 |cut -d "." -f1)
Timestamp=$(date +%Y-%m-%s-%H-%M-%S)
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

echo "script started ececuting at : $Timestamp" &>>$LOG_FILE_NAME
CHECK_ROOT

dnf module disable nginx -y &>>$LOG_FILE_NAME
VALIDATE $? "disabling nginx"

dnf module enable nginx:1.24 -y &>>$LOG_FILE_NAME
VALIDATE $? "Enabling new version"

dnf install nginx -y &>>$LOG_FILE_NAME
VALIDATE $? "installing nginx"

systemctl enable nginx &>>$LOG_FILE_NAME
VALIDATE $? "enabling nginx"

systemctl start nginx &>>$LOG_FILE_NAME
VALIDATE $? "starting nginx"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE_NAME
VALIDATE $? "removing defalut nginx"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE_NAME
VALIDATE $? "Downloading frontend"

cd /usr/share/nginx/html &>>$LOG_FILE_NAME
VALIDATE $? "changing directory"

unzip /tmp/frontend.zip &>>$LOG_FILE_NAME
VALIDATE $? "unzipping"

cp /home/ec2-user/roboshop-shell/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "conf success"

systemctl restart nginx &>>$LOG_FILE_NAME
VALIDATE $? "restarting nginx"

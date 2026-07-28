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

dnf module disable nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Disabling old version"

dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
VALIDATE $? "Enabling new version"

dnf install nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing nodejs"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop  &>>$LOG_FILE_NAME
VALIDATE $? "Adding user"

mkdir -p /app &>>$LOG_FILE_NAME
VALIDATE $? "creating directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip  &>>$LOG_FILE_NAME
VALIDATE $? "Downloading code"

cd /app &>>$LOG_FILE_NAME
VALIDATE $? "changing directory"

unzip /tmp/catalogue.zip &>>$LOG_FILE_NAME
VALIDATE $? "unzipping code"
 
npm install &>>$LOG_FILE_NAME
VALIDATE $? "installing dependencies"

cp /home/ec2-user/roboshop-shell/catalogue.service /etc/systemd/system/catalogue.service

systemctl daemon-reload  &>>$LOG_FILE_NAME
VALIDATE $? "daemon reload"

systemctl enable catalogue
VALIDATE $? "enabling catalogue"

systemctl start catalogue
VALIDATE $? "starting catalogue"

cp /home/ec2-user/roboshop-shell/mongo.repo /etc/yum.repos.d/mongo.repo

dnf install mongodb-mongosh -y &>>$LOG_FILE_NAME
VALIDATE $?

mongosh --host mongodb.aslearnings.fun </app/db/master-data.js &>>$LOG_FILE_NAME
VALIDATE $?

mongosh --host MONGODB-SERVER-IPADDRESS

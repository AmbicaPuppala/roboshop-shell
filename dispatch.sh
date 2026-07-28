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

dnf install golang -y &>>$LOG_FILE_NAME
VALIDATE $? "installing golang"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE_NAME
VALIDATE $? "adding user"

mkdir /app &>>$LOG_FILE_NAME
VALIDATE $? "creating directory"

curl -L -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip &>>$LOG_FILE_NAME
VALIDATE $? "downloading success"

cd /app &>>$LOG_FILE_NAME
VALIDATE $? "changing directory"

unzip /tmp/dispatch.zip &>>$LOG_FILE_NAME
VALIDATE $? "unzipping"

go mod init dispatch &>>$LOG_FILE_NAME
VALIDATE $? "dispatch"

go get &>>$LOG_FILE_NAME
VALIDATE $? "get"

go build &>>$LOG_FILE_NAME
VALIDATE $? "build"

cp /home/ec2-user/roboshop-shell/dispatch.service /etc/systemd/system/dispatch.service

systemctl daemon-reload &>>$LOG_FILE_NAME
VALIDATE $? "daemon reload"

systemctl enable dispatch &>>$LOG_FILE_NAME
VALIDATE $? "enabling dispatch"

systemctl start dispatch $LOG_FILE_NAME
VALIDATE $? "starting dispatch"
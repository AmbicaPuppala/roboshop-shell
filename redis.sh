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

mkdir -p $Log_Folder

echo"script started executing at : $Timestamp"  &>>LOG_FILE_NAME

CHECK_ROOT

dnf module disable redis -y &>>LOG_FILE_NAME
VALIDATE $? "Disabling old version"

dnf module enable redis:7 -y &>>LOG_FILE_NAME
VALIDATE $? "Enabling new version"

dnf install redis -y &>>LOG_FILE_NAME
VALIDATE $? "installing new version"

sed -i 's/^[[:space:]]*bind[[:space:]].*/bind 0.0.0.0/' /etc/redis/redis.conf
VALIDATE $? "bindip changing"

sed -i 's/^[[:space:]]*protected-mode[[:space:]]\+yes/protected-mode no/' /etc/redis/redis.conf
VALIDATE $? "protectedmode changing"

systemctl enable redis &>>LOG_FILE_NAME
VALIDATE $? "Enabling redis"

systemctl start redis  &>>LOG_FILE_NAME
VALIDATE $? "starting redis"
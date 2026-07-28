#!/bin/bash
USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

Log_Folder="/var/logs/roboshop-logs"
Log_File=$(echo $0+cut -d "." -f1)
Timestamp=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$Log_Folder+$Log_File-$Timestamp.log"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
       echo -e "$2...$R failure $N"
    else
        echo -e "$2...$G success $N"   
    fi    
}


CHECK_ROOT(){
    if[ $USERID -ne 0 ]
    then
        echo -e "you must have root user access $R"
        exit1
    fi
}

echo"script started executing at : $Timestamp" &>>LOG_FILE_NAME
CHECK_ROOT

cp home/ec2-user/roboshop-shell/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo

dnf install rabbitmq-server -y &>>LOG_FILE_NAME
VALIDATE $? "Installing rabbitmq-server"

systemctl enable rabbitmq-server &>>LOG_FILE_NAME
VALIDATE $? "Sstarting rabbitmq-server"

rabbitmqctl add_user roboshop roboshop123

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"

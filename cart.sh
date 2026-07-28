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
VALIDATE $? "Disabling nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
VALIDATE $? "Enabling NodeJs"

dnf install nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing NodeJs"

if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE_NAME
    VALIDATE $? "Adding user"
else
    echo "User already exists.. skipping"
fi      

mkdir -p /app  &>>$LOG_FILE_NAME
VALIDATE $? "creating directory"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOG_FILE_NAME
VALIDATE $? "Downloading code"

cd /app &>>$LOG_FILE_NAME
VALIDATE $? "changing directory"

unzip /tmp/cart.zip &>>$LOG_FILE_NAME
VALIDATE $? "unzipping"

npm install &>>$LOG_FILE_NAME
VALIDATE $? "Installing dependencies"

cp /home/ec2-user/roboshop-shell/cart.service /etc/systemd/system/cart.service

systemctl daemon-reload
VALIDATE $? "daemon reload"

systemctl enable cart
VALIDATE $? "enabling cart"

systemctl start cart
VALIDATE $? "starting cart"


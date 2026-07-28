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

dnf install python3 gcc python3-devel -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing python"

if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE_NAME
    VALIDATE $? "Adding user"
else
    echo "User already exists.. skipping"
fi    

mkdir -p /app &>>$LOG_FILE_NAME
VALIDATE $? "creating directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE_NAME
VALIDATE $? "downloading code"

cd /app  &>>$LOG_FILE_NAME
rm -rf /app/*
VALIDATE $? "changing directory"

unzip /tmp/payment.zip &>>$LOG_FILE_NAME
VALIDATE $? "unzipping"

pip3 install -r requirements.txt &>>$LOG_FILE_NAME
VALIDATE $? "installing pip3"

cp /home/ec2-user/roboshop-shell/payment.service /etc/systemd/system/payment.service

systemctl daemon-reload &>>$LOG_FILE_NAME
VALIDATE $? "daemon reload"

systemctl enable payment &>>$LOG_FILE_NAME
VALIDATE $? "enabling payment"

systemctl start payment &>>$LOG_FILE_NAME
VALIDATE $? "starting payment"






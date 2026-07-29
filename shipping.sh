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

mkdir -p $Log_Folder

echo "script started ececuting at : $Timestamp" &>>$LOG_FILE_NAME

CHECK_ROOT

dnf install maven -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing Maven"

id roboshop

if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE_NAME
    VALIDATE $? "Adding user"
else
    echo "User already exists.. skipping"
fi  

mkdir -p /app &>>$LOG_FILE_NAME
VALIDATE $? "creating directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE_NAME
VALIDATE $? "downloading code"

cd /app &>>$LOG_FILE_NAME
rm -rf /app/*
VALIDATE $? "changing directory"

unzip /tmp/shipping.zip &>>$LOG_FILE_NAME
VALIDATE $? "unzipping"

mvn clean package &>>$LOG_FILE_NAME
VALIDATE $? "clean package"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE_NAME
VALIDATE $? "moving jar file"

cp /home/ec2-user/roboshop-shell/shipping.service /etc/systemd/system/shipping.service

systemctl daemon-reload &>>$LOG_FILE_NAME
VALIDATE $? "daemon reload"

systemctl enable shipping  &>>$LOG_FILE_NAME
VALIDATE $? "enabling shipping"

systemctl start shipping &>>$LOG_FILE_NAME
VALIDATE $? "starting shipping"

dnf install mysql -y  &>>$LOG_FILE_NAME
VALIDATE $? " installing mysql"

mysql -h mysql.aslearnings.fun -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE_NAME
VALIDATE $? "schema loading"

mysql -h mysql.aslearnings.fun -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$LOG_FILE_NAME
VALIDATE $? "app user authentication"

mysql -h mysql.aslearnings.fun -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE_NAME
VALIDATE $? "Load master data"

systemctl restart shipping
VALIDATE $? "restart shipping"

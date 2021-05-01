#! /bin/bash
yum update
yum -y install java-1.8.0-openjdk
aws s3 cp s3://aws-training-pythonrocks-20210401/persist3-2021-0.0.1-SNAPSHOT.jar ~/
echo "RDS_HOST=${rds_host}" >> /etc/environment
java -jar /root/persist3-2021-0.0.1-SNAPSHOT.jar 2&>1 > /var/log/calc.log &

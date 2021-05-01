#! /bin/bash
yum update
yum -y install java-1.8.0-openjdk
aws s3 cp s3://aws-training-pythonrocks-20210401/calc-2021-0.0.2-SNAPSHOT.jar ~/
java -jar /root/calc-2021-0.0.2-SNAPSHOT.jar 2&>1 > /var/log/calc.log &

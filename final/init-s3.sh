BUCKET="s3://aws-training-pythonrocks-20210401"
aws s3 mb $BUCKET
aws s3 cp ./calc-2021-0.0.2-SNAPSHOT.jar $BUCKET
aws s3 cp ./persist3-2021-0.0.1-SNAPSHOT.jar $BUCKET

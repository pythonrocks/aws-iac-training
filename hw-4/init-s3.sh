#!/bin/bash
BUCKET="s3://aws-training-pythonrocks-20210401"
aws s3 mb $BUCKET
aws s3 cp ./dynamodb-script.sh $BUCKET
aws s3 cp ./rds-script.sql $BUCKET

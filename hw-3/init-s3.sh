#!/bin/bash
echo "simple small text file" > testfile.txt
BUCKET="s3://aws-training-pythonrocks-20210322"
aws s3 mb $BUCKET
aws s3 cp ./testfile.txt $BUCKET
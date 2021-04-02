#! /bin/bash
BUCKET=${s3_bucket}
aws s3 cp $BUCKET/rds-script.sql ~/
aws s3 cp $BUCKET/dynamodb-script.sh ~/

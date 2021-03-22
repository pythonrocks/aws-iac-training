#! /bin/bash
BUCKET=${s3_bucket}
PREFIX=${s3_prefix}
aws s3 cp $BUCKET/$PREFIX ~/
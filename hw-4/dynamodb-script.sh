#!/bin/sh

aws --region us-west-2 dynamodb list-tables

echo "add record into table"
aws --region us-west-2 dynamodb put-item \
    --table-name games  \
    --item \
        '{"title": {"S": "Paper Mario"}, "publisher": {"S": "Nintendo"}}'

echo "add one more record into table"
aws --region us-west-2 dynamodb put-item \
    --table-name games  \
    --item \
        '{"title": {"S": "Hades"}, "publisher": {"S": "Supergiant Games"}}'

aws --region us-west-2 dynamodb scan --table-name games

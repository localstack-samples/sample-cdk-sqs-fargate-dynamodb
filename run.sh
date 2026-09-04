#!/bin/bash
SQS_QUEUE="sqs-fargate-queue"
NETWORK_NAME="localstack-shared-net"

echo "List queues to check if sqs queue was created"
lstk aws sqs list-queues
echo "List tables to check if dynmodb table was created"
lstk aws dynamodb list-tables

echo "Send message to the sqs queue that should be stored in the db"
lstk aws sqs send-message --queue $SQS_QUEUE --message-body '{"message": "hello world"}'

echo "Giving the container time to write the message, then check if the fargate container successfully wrote the sqs message into the dynamodb table"
sleep 3
lstk aws dynamodb scan --table-name sqs-fargate-ddb-table


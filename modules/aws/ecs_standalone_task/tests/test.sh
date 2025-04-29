#!/usr/bin/env bash
CLUSTER_ARN="arn:aws:ecs:us-east-2:533267011653:cluster/UnitTestEnv-mike"
TASK_DEFINITION_ARN="arn:aws:ecs:us-east-2:533267011653:task-definition/UnitTestEnv-mike:1"
SUBNETS="subnet-0ef3e8997d0f0ffa3,subnet-0ba6cd0e5961de7dc,subnet-025525f6545e8e311"
SECURITY_GROUP_ID="sg-02c77decc0b937310"

ARN=`AWS_PROFILE=apres-sandbox aws ecs run-task \
--cluster $CLUSTER_ARN \
--count 1 \
--launch-type FARGATE \
--task-definition $TASK_DEFINITION_ARN \
--network-configuration "awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$SECURITY_GROUP_ID],assignPublicIp=DISABLED}" | jq -r '.tasks[0].containers[0].taskArn'`

echo "Running task ARN: $ARN"
while [ 1 ]
do
    STATUS=`AWS_PROFILE=apres-sandbox aws ecs describe-tasks --cluster ${CLUSTER_ARN} --tasks $ARN | jq -r '.tasks[0].containers[0].lastStatus'`
    if [ "$STATUS" == "STOPPED" ]; then
        EXIT_CODE=`AWS_PROFILE=apres-sandbox aws ecs describe-tasks --cluster ${CLUSTER_ARN} --tasks $ARN | jq -r '.tasks[0].containers[0].exitCode'`
        echo "Task stopped with exit code: $EXIT_CODE"
        if [ "$EXIT_CODE" == "0" ]; then
            exit 0
        else
            exit 1
        fi
    fi
    sleep 1
done
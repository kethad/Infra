#!/bin/bash

CFT=$1
Region=$2
echo "$CFT cloudformation template name in $(basename $0) script"

while :
do
 
 echo "checking statck existance"
 /usr/local/bin/aws cloudformation wait stack-exists --stack-name $CFT --region $Region
 
 echo "Check Cloudformation Template status"
 CFStatus=$(/usr/local/bin/aws cloudformation describe-stacks --stack-name $CFT --region $Region --query "Stacks[0].StackStatus" | xargs)
 echo "$CFStatus is the status of Reader Instance Status"

 if [ $CFStatus == 'CREATE_COMPLETE' ]
 then
    echo "${CFStatus} is the status of the CloudFromation stack, so coming out of the $(basename $0) script"
    exit 0
 elif [ $CFStatus == 'ROLLBACK_FAILED' ]
 then
    echo "${CFStatus} is the status of the CloudFromation stack, so coming out of the $(basename $0) script"
    exit 1
 else
    echo "slepping for 60s"
    sleep 60
 fi

done

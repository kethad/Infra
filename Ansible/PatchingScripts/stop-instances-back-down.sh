#!/bin/bash
echo "$1","$2","$3"
log_path="/local/apps/infra/patching_logs"
DATE=$(date +%d-%^h-%Y)
for ec2id in `cat $log_path/$DATE/all-$1-$2-stopped-instances-ids-$(date +%Y-%m-%d)*.log`
do
        if [[ $(/usr/local/bin/aws ec2 describe-instances --region $3 --instance-ids $ec2id --query 'Reservations[].Instances[].State[].Name' --output text) == "running" ]]
        then
        /usr/local/bin/aws ec2 stop-instances --region $3 --instance-ids $ec2id
        fi
done



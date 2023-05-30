#!/bin/bash
echo "$1","$2","$3"
log_path="/local/apps/infra/patching_logs"
DATE=$(date +%d-%^h-%Y)
if [ -e  $log_path/stopped_instances/all-$1-$2-stopped-instances-ids-$(date +%Y-%m-%d)*.log ]
then
	for ec2id in `cat $log_path/stopped_instances/all-$1-$2-stopped-instances-ids-$(date +%Y-%m-%d)*.log`
	do
        if [[ $(/usr/local/bin/aws ec2 describe-instances --region $3 --instance-ids $ec2id --query 'Reservations[].Instances[].State[].Name' --output text) == "running" ]]
        then
        /usr/local/bin/aws ec2 stop-instances --region $3 --instance-ids $ec2id
        fi
	done
else
   echo "There are no stopped instances before starting the patching activity"
fi

#mv $log_path/$DATE $log_path/$DATE-$1-$2-$4

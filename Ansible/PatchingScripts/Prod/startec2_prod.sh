#!/bin/bash
echo "$1", "$2", "$3", "$4", "$5", "$6" "$7"
log_path="/local/apps/infra/patching_logs"
DATE=$(date +%d-%^h-%Y)
mkdir -m 0755 -p $log_path/$DATE-$2-$6-$7

if [ -d $log_path/stopped_instances ]
then
echo "$log_path/stopped_instances is available"
else
echo "$log_path/stopped_instances not available"
echo "###########Creating $log_path/stopped_instances Directory#######"
mkdir -m 0755 -p $log_path/stopped_instances
fi

#if [ ! -e "$log_path/$DATE/all-$2-$6-instances-ips-$(date +%Y-%m-%d).log" ]
#then
#mkdir -p $log_path/$DATE/bkp-$(date +%Y-%m-%d) > /dev/null 2>&1
#mv $DATE $DATE-bkp-$(date +%Y-%m-%d:%H:%M:%S) > /dev/null 2>&1
#mv $log_path/$DATE/all-$2-$6-stopped-instances*.log $log_path/$DATE/bkp-$(date +%Y-%m-%d) > /dev/null 2>&1
#mv $log_path/$DATE/all-$2-$6-instances*.log $log_path/$DATE/bkp-$(date +%Y-%m-%d) > /dev/null 2>&1

#for ec2id in $(/usr/local/bin/aws ec2 describe-instances --filter --region $1 Name=tag:Patching,Values=Yes Name=tag:OS,Values=Linux Name=tag:Environment,Values=[$2,PREPROD] Name=tag:Owner,Values=[$3] Name=tag:AZ,Values=[$4] Name=tag:UsedFor,Values="$5" Name=tag:BuildNumber,Values=[723]  | grep -i InstanceId | awk -F\" '{ print $4 }')
for ec2id in $(/usr/local/bin/aws ec2 describe-instances --filter --region $1 Name=tag:Environment,Values=[$2,PREPROD] Name=tag:Owner,Values=[$3] Name=tag:AZ,Values=[$4]  Name=tag:UsedFor,Values="$5" Name=tag:Patching,Values=Yes Name=tag:OS,Values=Linux | grep -i InstanceId | awk -F\" '{ print $4 }')
do
if [[ $(/usr/local/bin/aws ec2 describe-instances --region $1 --instance-ids $ec2id --query 'Reservations[].Instances[].State[].Name' --output text) != "terminated" ]]
then
ec2ip=$(/usr/local/bin/aws ec2 describe-instances --region $1 --instance-ids $ec2id --query 'Reservations[].Instances[].PrivateIpAddress' --output text)
echo "$ec2ip" | tee -a $log_path/$DATE-$2-$6-$7/all-$2-$6-instances-ips-$(date +%Y-%m-%d).log
if [[ $(/usr/local/bin/aws ec2 describe-instances --region $1 --instance-ids $ec2id --query 'Reservations[].Instances[].State[].Name' --output text) == "stopped" ]]
then
echo "$ec2id" | tee -a $log_path/stopped_instances/all-$2-$6-stopped-instances-ids-$(date +%Y-%m-%d).log
/usr/local/bin/aws ec2 start-instances --region $1 --instance-ids $ec2id
fi
fi
done
if [ -s "$log_path/stopped_instances/all-$2-$6-stopped-instances-ids-$(date +%Y-%m-%d).log" ]
then
#sed -e "s/\r//g" ${log_path}/$DATE/all-$2-$6-stopped-instances-ids-$(date +%Y-%m-%d).log | mutt -s "SPDJI AWS EC2 $2 PATCHING : STOPPED INSTANCES in $1" "kirubakaran.kannan@spglobal.com"
sed -e "s/\r//g" ${log_path}/stopped_instances/all-$2-$6-stopped-instances-ids-$(date +%Y-%m-%d).log | EMAIL="IndexInfraMBX@spglobal.com" mutt -s "SPDJI AWS EC2 PATCHING : STOPPED INSTANCES on $2 Environment in $6 Region" "InfraNotificationMBX@spglobal.com,IndexInfraMBX@spglobal.com,SPDJIAppSupport@spglobal.com" "IndexInfraMBX@spglobal.com"
#mv $log_path/$DATE/all-$2-$6-stopped-instances-ids-$(date +%Y-%m-%d).log $log_path/$DATE/all-$2-$6-stopped-instances-ids-$(date +%Y-%m-%d:%H:%M:%S).log > /dev/null 2>&1
#fi
fi

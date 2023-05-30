#!/bin/bash
echo "$1", "$2", "$3", "$4", "$5", "$6", "$7"
log_path="/local/apps/infra/patching_logs"
DATE=$(date +%d-%^h-%Y)
for ec2id in $(/usr/local/bin/aws ec2 describe-instances --filter --region $1 Name=tag:Environment,Values=[$2] Name=tag:Owner,Values=[$3] Name=tag:AZ,Values=[$4]  Name=tag:UsedFor,Values="$5" Name=tag:Patching,Values=No Name=tag:OS,Values=Linux | grep -i InstanceId | awk -F\" '{ print $4 }' )
do
if [[ $(/usr/local/bin/aws ec2 describe-instances --region $1 --instance-ids $ec2id --query 'Reservations[].Instances[].State[].Name' --output text) != "terminated" ]]
then
ec2ip=$(/usr/local/bin/aws ec2 describe-instances --region $1 --instance-ids $ec2id --query 'Reservations[].Instances[].PrivateIpAddress' --output text)
echo "$ec2ip" | tee -a $log_path/$DATE-$2-$6-$7/nonpatched-$2-$6-instances-ips-$(date +%Y-%m-%d).log
fi
done
#sed -e "s/\r//g" ${log_path}/$DATE/all-$2-$6-stopped-instances-ids-$(date +%Y-%m-%d).log | EMAIL="IndexInfraMBX@spglobal.com" mutt -s "SPDJI AWS EC2 PATCHING : STOPPED INSTANCES on $2 Environment in $6 Region" "kirubakaran.kannan@spglobal.com"
if [[ -f $log_path/$DATE-$2-$6-$7/nonpatched-$2-$6-instances-ips-$(date +%Y-%m-%d).log ]]
then
if [[ -s $log_path/$DATE-$2-$6-$7/nonpatched-$2-$6-instances-ips-$(date +%Y-%m-%d).log ]]
then
#sed -e "s/\r//g" ${log_path}/$DATE-$2-$6-$7/nonpatched-$2-$6-instances-ips-$(date +%Y-%m-%d).log | EMAIL="IndexInfraMBX@spglobal.com" mutt -s "SPDJI AWS EC2 PATCHING : Non Patched Servers on $2 Environment in $6 Region" "indexinfrastructure@spglobal.com" "IndexInfraMBX@spglobal.com"
echo "Above listed servers are tagged with Patching Tag "No", Please patch them manually during the change window itself once all the application and database servers patching is completed" |EMAIL="IndexInfraMBX@spglobal.com" mutt -s "SPDJI AWS EC2 PATCHING : Non Patched Servers on $2 Environment in $6 Region" "indexinfrastructure@spglobal.com" "IndexInfraMBX@spglobal.com" -i ${log_path}/$DATE-$2-$6-$7/nonpatched-$2-$6-instances-ips-$(date +%Y-%m-%d).log
else
echo "All Servers have been patched on $2 Environment in $1 Region" | EMAIL="IndexInfraMBX@spglobal.com" mutt -s "SPDJI AWS EC2 PATCHING : Non Patched Servers on $2 Environment in $6 Region" "indexinfrastructure@spglobal.com" "IndexInfraMBX@spglobal.com"
fi
else
echo "All Servers have been patched on $2 Environment in $1 Region" | EMAIL="IndexInfraMBX@spglobal.com" mutt -s "SPDJI AWS EC2 PATCHING : Non Patched Servers on $2 Environment in $6 Region" "indexinfrastructure@spglobal.com" "IndexInfraMBX@spglobal.com"
fi

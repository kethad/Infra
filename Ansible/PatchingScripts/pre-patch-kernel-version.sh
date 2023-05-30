#!/bin/bash
echo "$1" "$2"
DATE=$(date +%d-%^h-%Y)
log_path="/local/apps/infra/patching_logs"
if [ ! -e "$log_path/$DATE/prepatch-$1-$2-mail-body-host-with-kernel-$(date +%Y-%m-%d).txt" ]
then
mkdir -p $log_path/$DATE/bkp-$(date +%Y-%m-%d) > /dev/null 2>&1
mv $log_path/$DATE/prepatch-$1-$2-mail-body-host-with-kernel*.txt $log_path/$DATE/bkp-$(date +%Y-%m-%d)/prepatch-$1-$2-mail-body-host-with-kernel-$(date +%Y-%m-%d:%H:%M:%S).txt > /dev/null 2>&1
mv $log_path/$DATE/prepatch-$1-$2-kernelversion*.log $log_path/$DATE/bkp-$(date +%Y-%m-%d)/prepatch-$1-$2-kernelversion-$(date +%Y-%m-%d:%H:%M:%S).log > /dev/null 2>&1

for i in `cat $log_path/$DATE/reachable-hosts-$(date +%Y-%m-%d).log`
do
sshpass ssh -o ConnectTimeout=30 -o StrictHostKeyChecking=no -t anscm@$i "hostname -i; uname -r" | tee -a $log_path/$DATE/prepatch-$1-$2-kernelversion-$(date +%Y-%m-%d).log
done
awk '{printf "%s%s",$0,NR%2?"\t\t":RS}' < $log_path/$DATE/prepatch-$1-$2-kernelversion-$(date +%Y-%m-%d).log | tee -a $log_path/$DATE/prepatch-$1-$2-mail-body-host-with-kernel-$(date +%Y-%m-%d).txt
#sed -e "s/\r//g" ${log_path}/$DATE/prepatch-$1-$2-mail-body-host-with-kernel-$(date +%Y-%m-%d).txt | EMAIL="IndexInfraMBX@spglobal.com" mutt -s "SPDJI AWS EC2 PATCHING : PRE-PATCH KERNEL VERSION on $1 Environment in $2 Region" "kirubakaran.kannan@spglobal.com"
#sed -e "s/\r//g" ${log_path}/$DATE/prepatch-$1-$2-mail-body-host-with-kernel-$(date +%Y-%m-%d).txt | EMAIL="IndexInfraMBX@spglobal.com" mutt -s "SPDJI AWS EC2 PATCHING : PRE-PATCH KERNEL VERSION on $1 Environment in $2 Region" "IndexInfraNotification@spglobal.com,IndexInfraMBX@spglobal.com,SPDJIAppSupport@spglobal.com" "IndexInfraMBX@spglobal.com"
sed -e "s/\r//g" ${log_path}/$DATE/prepatch-$1-$2-mail-body-host-with-kernel-$(date +%Y-%m-%d).txt | EMAIL="IndexInfraMBX@spglobal.com" mutt -s "SPDJI AWS EC2 PATCHING : PRE-PATCH KERNEL VERSION on $1 Environment in $2 Region" "IndexInfraNotification@spglobal.com,IndexInfraMBX@spglobal.com" "IndexInfraMBX@spglobal.com"
fi

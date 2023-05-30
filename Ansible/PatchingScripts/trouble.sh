#!/bin/bash
####RPMDB ERROR######
echo "$1" "$2"
log_path="/local/apps/infra/patching_logs"
DATE=$(date +%d-%^h-%Y)
for ip in `cat $log_path/$DATE/reachable-hosts-$(date +%Y-%m-%d).log`
do
sshpass ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -t anscm@$ip "if ! sudo yum list installed; then sudo mkdir -p /opt/rpm-$(date +%Y-%m-%d); sudo mv /var/lib/rpm/__db* /opt/rpm-$(date +%Y-%m-%d); sudo yum clean all; fi" | tee -a $log_path/$DATE/$1-$2-rpmdb-error-$(date +%Y-%m-%d).log
done

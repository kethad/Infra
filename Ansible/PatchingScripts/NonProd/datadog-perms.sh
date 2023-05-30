#!/bin/bash
echo "$1", "$2", "$3"
log_path="/local/apps/infra/patching_logs"
DATE=$(date +%d-%^h-%Y)
for i in `cat $log_path/$DATE-$1-$2-$3/reachable-hosts-$(date +%Y-%m-%d).log`
do
sshpass ssh -o ConnectTimeout=15 -o StrictHostKeyChecking=no -t anscm@$i "sudo chmod 750 /opt/datadog-agent/; sudo systemctl restart datadog-agent" | tee -a $log_path/$DATE-$1-$2-$3/datadog-perms-$(date +%Y-%m-%d).log
done

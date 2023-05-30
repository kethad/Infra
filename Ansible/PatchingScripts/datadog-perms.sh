#!/bin/bash
log_path="/local/apps/infra/patching_logs"
DATE=$(date +%d-%^h-%Y)
for i in `cat $log_path/$DATE/reachable-hosts-$(date +%Y-%m-%d).log`
do
sshpass ssh -o ConnectTimeout=15 -o StrictHostKeyChecking=no -t anscm@$i "sudo chmod 750 /opt/datadog-agent/; sudo systemctl stop datadog-agent; sudo systemctl disable datadog-agent" | tee -a $log_path/$DATE/datadog-perms-$(date +%Y-%m-%d).log
done

#!/bin/bash
echo "$1","$2","$3"
log_path="/local/apps/infra/patching_logs"
DATE=$(date +%d-%^h-%Y)
for ip in `cat $log_path/$DATE-$1-$2-$3/reachable-hosts-$(date +%Y-%m-%d).log`
do
sshpass ssh -o ConnectTimeout=30 -o StrictHostKeyChecking=no -t anscm@$ip "sudo hostname -i; if [ -f /usr/libexec/platform-python3.6 ]; then sudo ln -f -s /usr/libexec/platform-python3.6 /usr/bin/python; fi"
done

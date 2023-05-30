#!/bin/bash
#echo "$1"
for i in $(echo $1 | tr "," "\n")
do
        echo $i >> "$3/workspace/$4/ansible/infra/PatchingScripts/IP-inv-$2"
done

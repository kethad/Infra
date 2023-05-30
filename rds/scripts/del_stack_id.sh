#!/bin/bash

stackname=$1
envapp=$2
build_number=$3
region=$4
aws cloudformation describe-stacks --stack-name ${stackname} --region ${region} | grep -w StackId | xargs | tr -d , | awk '{ print $2 }' > /var/tmp/${envapp}-${build_number}

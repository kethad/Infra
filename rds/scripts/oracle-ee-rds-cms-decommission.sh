#!/bin/bash

dbinstanceidentifier=$1
region=$2


echo "$dbinstanceidentifier is dbinstanceidentifier value"
echo "$region is region variable value "

if [ -z $dbinstanceidentifier ]
then
   
    echo "coming out of $(basename $0) since dbinstanceidentifier is empty"
    exit
fi

if [ -z $region ]
then
    
    echo "coming out of $(basename $0) since region value is empty"
    exit
fi

aws rds describe-db-instances --db-instance-identifier ${dbinstanceidentifier} --region $region > /dev/null 2>&1
dbstatus=$?
echo "$dbstatus is db instance identifer status before it's deletion,0 means exists, other than 0 means doesn't exists"
if [ $dbstatus == 0 ]
then
    echo "Removing db instance identifier "
    aws rds delete-db-instance --db-instance-identifier ${dbinstanceidentifier} --region $region --final-db-snapshot-identifier ${dbinstanceidentifier}-finalsnapshot
else
    echo "seems db instance identifer doesn't exist"
fi

echo "sleeping for 8 mins since DB Instance Identifier deletion would take some more time"
sleep 480

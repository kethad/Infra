#!/bin/bash

#APP=$4

echo $APP Is the APP Name in tags script

if [ $APP == 'CIP' ]
then
   echo "$APP is the AppName"
   AppID="67C80796-C9A6-466B-B824-7578C9082115"
   echo "$AppID is the appid for CIP"
elif [ $APP == 'MDB' ]
then
   echo "$APP is the AppName"
   AppID="27932A31-F152-45C4-AB96-C933C978418B"
   echo "$AppID is the appid for MDB"
else
   echo "App is not CIP or MDB"
fi

#Owner=$4
UsedFor=RDS
#Environment=$3
BU=DJI

for item in "$@"
do
   echo $item is stack identifier
   dbinstancearn=$(aws rds describe-db-instances --db-instance-identifier $item --region us-west-2 | grep "DBInstanceArn" | awk '{ print $2 }' | tr -d "," | xargs)
   echo "$dbinstancearn"
   aws rds add-tags-to-resource --region us-west-2 --resource-name $dbinstancearn --tags "[{\"Key\": \"Owner\",\"Value\": \"$APP\"},{\"Key\": \"AppID\",\"Value\": \"$AppID\"},{\"Key\": \"Environment\",\"Value\": \"$Environment\"},{\"Key\": \"BU\",\"Value\": \"$BU\"},{\"Key\": \"UsedFor\",\"Value\": \"$UsedFor\"}]"


done

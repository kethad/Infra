#!/bin/bash

stackname=$1
envapp=$2  ##similar to envapp
buildid=$3
buildusermailid=$4
region=$5
drclusteridentifier=$6
enginetype=$7
stackdeletion=$8

#envapp=$7
#builduser=$5

#BuildUser=$(echo $builduser | tr ' ' '_')


if [ -z "$stackname" ]
then
   echo "$stackname variable value seems empty, coming out of $(basename $0)"
   exit
fi

if [ -z "$envapp" ]
then
   echo "$envapp variable value seems empty, coming out of $(basename $0)"
   exit
fi

if [ -z "$buildid" ]
then
   echo "$buildid variable value seems empty, coming out of $(basename $0)"
   exit
fi


if [ -z "$region" ]
then
   echo "$region variable value seems empty, coming out of $(basename $0)"
   exit
fi

if [ -z "$drclusteridentifier" ]
then
   echo "$drclusteridentifier variable value seems empty, coming out of $(basename $0)"
   exit
fi

dir=$(pwd)/rds
echo "$dir is dir in $(basename $0)"
filename=$dir/$envapp.cfvars.txt

if [ -f $filename ]
then
    rm -f $filename
    echo "$filename is removed"
else
     echo "cfvars.txt file is not existing"
fi

cd $dir

sudo chmod +x  $dir/spider_aurora_mysql_prod_cf.py
sudo chmod +x $dir/UpdateBuildState.py
sudo chmod +x $dir/mysql_postgresql_nonprod_cf.py

#echo "Going to execute aurora_postgresql_prod_cf.py python cf script"

#./aurora_postgresql_prod_cf.py  $stackname $region $envapp $drclusteridentifier
#./prod_dr_mdb_aurora_postg_cf.py  $stackname $region $envapp $drclusteridentifier


################
if [ $enginetype == "mysql" ]
then
     echo "Going to execute mysql_postgresql_nonprod_cf.py python cf script"
    ./mysql_postgresql_nonprod_cf.py $stackname $region $envapp
else
    
    echo "Going to execute aurora_postgresql_prod_cf.py python cf script"
   ./spider_aurora_mysql_prod_cf.py  $stackname $region $envapp $drclusteridentifier
fi

################

if [ -z "$stackdeletion" ]
then
   echo "$stackdeletion is stackdeletion value"
   echo "wrapper script will continue to update dynamodb table since stackdeletion variable empty"
else
    echo "$stackdeletion is stackdeletion value"
    echo "wrapper script will exit since stackdeletion variable not empty"
    exit
fi

dos2unix $filename

#ReaderEndpoint=$(cat $filename | grep -w ReaderEndpoint | cut -d ":" -f2)
#echo $rdsendpoint is rdsendpoint value

InstanceName=$(cat $filename | grep -w InstanceName | cut -d ":" -f2 | tr -d ' ')
#echo $instancename is instancename value

DBEngine=$(cat $filename | grep -w DBEngine | cut -d ":" -f2 | tr -d ' ')
DBEngine_Version=$(cat $filename | grep -w "DBEngine_Version" | cut -d ":" -f2 | tr -d ' ')
DBInstanceClass=$(cat $filename | grep -w DBInstanceClass | cut -d ":" -f2)
#DBGlobalClusterIdentifier=$(cat $filename | grep -w DBGlobalClusterIdentifier | cut -d ":" -f2)
ClusterName=$(cat $filename | grep -w ClusterName | cut -d ":" -f2)
PrimaryWriterEndpoint=$(cat $filename | grep -w PrimaryWriterEndpoint | cut -d ":" -f2)
PrimaryReaderEndpoint=$(cat $filename | grep -w PrimaryReaderEndpoint | cut -d ":" -f2)
SecondaryWriterEndPoint=$(cat $filename | grep -w SecondaryWriterEndPoint | cut -d ":" -f2)
SecondaryClusterIdentifier=$(cat $filename | grep -w SecondaryClusterIdentifier | cut -d ":" -f2)
SecondaryReaderEndPoint=$(cat $filename | grep -w SecondaryReaderEndPoint | cut -d ":" -f2)
EndPoint=$(cat $filename | grep -w EndPoint | cut -d ":" -f2 | tr -d ' ' )
MultiAZ=$(cat $filename | grep -w MultiAZ | cut -d ":" -f2 | tr -d ' ' )

dt="$(date +"%Y-%m-%d %T")"

if [[ -n $envapp && -n $buildid && -n $EndPoint && -n $InstanceName ]]
then
   echo "updating prod spdji-rds-inventory DynamoDB table for the MYSQL Engine"
   $dir/UpdateBuildState.py  AppName=$envapp  BuilID=$buildid EndPoint=$EndPoint InstanceName=$InstanceName DBEngine=$DBEngine DBEngine_Version=$DBEngine_Version MultiAZ=$MultiAZ  Build_User_Mail_ID=$buildusermailid DatenTime="$dt"
else
   echo "envapp buildid EndPoint InstanceName one of these variables are not defined"
fi

if [[ -n $envapp && -n $buildid && -n $PrimaryWriterEndpoint && -n $PrimaryReaderEndpoint && -n $SecondaryWriterEndPoint && -n $SecondaryReaderEndPoint ]]
then

    echo "updating prod spdji-rds-inventory DynamoDB table for the Aurora PostgreSQL Engine"
    $dir/UpdateBuildState.py  AppName=$envapp  BuilID=$buildid ClusterName=$ClusterName PrimaryWriterEndpoint=$PrimaryWriterEndpoint  PrimaryReaderEndpoint=$PrimaryReaderEndpoint SecondaryClusterIdentifier=$SecondaryClusterIdentifier SecondaryWriterEndPoint=$SecondaryWriterEndPoint SecondaryReaderEndPoint=$SecondaryReaderEndPoint DBEngine=$DBEngine DBEngine_Version=$DBEngine_Version  Build_User_Mail_ID=$buildusermailid  DatenTime="$dt"
else
    echo "envapp buildid ClusterEndpoint ReaderEndpoint one of these variable are not defined"
fi

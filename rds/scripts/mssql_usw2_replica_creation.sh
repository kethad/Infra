#!/bin/bash

SourceDBInstanceIdentifier=$1
ReplicaIdentifier=$2
region=$3     ##source db region 
Environment=$4
APP=$5
BuildID=$6    ###User Input Build Number

##NonProd Variables
AppID='CCBE9072-1B6A-5910-B29F-A756624BCBC9'
NP_DbSubnetGroupName='uat-rds-new-private-subnet-group'    ##'uat-usw2-pvt-subnet-group'##
NP_DBParameterGroupName='beta-usw2-care-param-oracle'
NP_VPCSecurityGroupIds='sg-021d935484a5770b7'
NP_KMSKeyId='567a53fa-2370-4e99-9398-ac7a07245b0e'
NP_PerformanceInsightsKmsKeyId='arn:aws:kms:us-west-2:699183880494:key/567a53fa-2370-4e99-9398-ac7a07245b0e'
NP_MonitoringRoleArn='arn:aws:iam::699183880494:role/rds-monitoring-role'
MaxAllocatedStorage=2048
MonitoringInterval=60
PerformanceInsightsRetentionPeriod=7


###PROD Variables
P_DbSubnetGroupName='dr-usw2-priv-rds-subnet-group-01'
P_DBParameterGroupName='dr-edm-param-mssql'
P_VPCSecurityGroupIds='sg-0987ac9c16541d87f'
P_KMSKeyId='54058ae8-1bd9-4522-84c9-d09e6b4486a0'
P_MonitoringRoleArn='arn:aws:iam::897860998156:role/Prod-RDS-EnhanceMonitoring-Role'
P_PerformanceInsightsKmsKeyId='arn:aws:kms:us-west-2:897860998156:key/54058ae8-1bd9-4522-84c9-d09e6b4486a0'
P_MaxAllocatedStorage=3072


if [ -z ${SourceDBInstanceIdentifier} ]
then
   echo "source-db-instance-identifier value seems empty, so coming out of $(basename $0)"
   exit
fi

sourcedbinstanceidentifierarn=$(aws rds describe-db-instances --region us-east-1 --db-instance-identifier  ${SourceDBInstanceIdentifier} | grep -w "DBInstanceArn" | awk '{ print $2}' | tr -d '",')

echo "$sourcedbinstanceidentifierarn is source db instance identifier ARN"



if [ -z ${sourcedbinstanceidentifierarn} ]
then
   echo "sourcedbinstanceidentifierarn variable value seems empty so coming out of $(basename $0)"
   exit
fi

if [ -z ${ReplicaIdentifier} ]
then
   echo "ReplicaIdentifier variable value seems empty so coming out of $(basename $0)"
   exit
fi

if [ -z ${Environment} ]
then
   echo "${Environment} is Environment variable value, seems empty so coming out of $(basename $0)"
   exit
fi

if [ -z ${APP} ]
then
   echo "${APP} is APP variable value, seems empty so coming out of $(basename $0)"
   exit
fi


##https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html  url for certificate bundle information
##Creating the read replica for MS SQL in Oregon with tags

if [[ $Environment == "UAT" || $Environment == "uat" ]]
then
    echo " Environment is $Environment "
    aws rds create-db-instance-read-replica --deletion-protection --db-instance-identifier ${ReplicaIdentifier} --source-db-instance-identifier ${sourcedbinstanceidentifierarn} --source-region us-east-1 --db-subnet-group-name ${NP_DbSubnetGroupName} --vpc-security-group-ids ${NP_VPCSecurityGroupIds} --kms-key-id ${NP_KMSKeyId}  --region us-west-2 --max-allocated-storage ${MaxAllocatedStorage} --enable-cloudwatch-logs-exports "agent" "error" --enable-performance-insights --performance-insights-retention-period ${PerformanceInsightsRetentionPeriod} --performance-insights-kms-key-id ${NP_PerformanceInsightsKmsKeyId} --monitoring-interval ${MonitoringInterval} --monitoring-role-arn ${NP_MonitoringRoleArn} --tags "[{\"Key\": \"Build_Number\",\"Value\": \"${BuildID}\"},{\"Key\": \"Owner\",\"Value\": \"${APP}\"},{\"Key\": \"AppID\",\"Value\": \"${AppID}\"},{\"Key\": \"Environment\",\"Value\": \"${Environment}\"},{\"Key\": \"BU\",\"Value\": \"DJI\"},{\"Key\": \"UsedFor\",\"Value\": \"MS SQL Database\"}]"
    echo " Waiting for the Replica DB Instances to come to Available state..."
    sleep 20m
    aws rds wait db-instance-available --db-instance-identifier ${ReplicaIdentifier} --region us-west-2     
    aws rds modify-db-instance --db-instance-identifier ${ReplicaIdentifier} --region us-west-2 --ca-certificate-identifier rds-ca-rsa2048-g1 --deletion-protection --apply-immediately
    
elif [[ $Environment == "PROD" || $Environment == "PREPROD" ]]
then 
     echo " Environment is $Environment "
     aws rds create-db-instance-read-replica --deletion-protection --db-instance-identifier ${ReplicaIdentifier} --source-db-instance-identifier ${sourcedbinstanceidentifierarn} --source-region us-east-1 --db-subnet-group-name ${P_DbSubnetGroupName} --vpc-security-group-ids ${P_VPCSecurityGroupIds} --kms-key-id ${P_KMSKeyId}  --region us-west-2 --max-allocated-storage ${P_MaxAllocatedStorage} --enable-cloudwatch-logs-exports "agent" "error" --enable-performance-insights --performance-insights-retention-period ${PerformanceInsightsRetentionPeriod} --performance-insights-kms-key-id ${P_PerformanceInsightsKmsKeyId} --monitoring-interval ${MonitoringInterval} --monitoring-role-arn ${P_MonitoringRoleArn} --tags "[{\"Key\": \"Build_Number\",\"Value\": \"${BuildID}\"},{\"Key\": \"Owner\",\"Value\": \"${APP}\"},{\"Key\": \"AppID\",\"Value\": \"${AppID}\"},{\"Key\": \"Environment\",\"Value\": \"${Environment}\"},{\"Key\": \"BU\",\"Value\": \"DJI\"},{\"Key\": \"UsedFor\",\"Value\": \"MS SQL Database\"}]"
     echo " Waiting for the Replica DB Instances to come to Available state..."
     sleep 20m
     aws rds wait db-instance-available --db-instance-identifier ${ReplicaIdentifier} --region us-west-2     
     aws rds modify-db-instance --db-instance-identifier ${ReplicaIdentifier} --region us-west-2 --ca-certificate-identifier rds-ca-rsa2048-g1 --deletion-protection --apply-immediately
else
    echo " Environment is $Environment "
    echo "environment should be either UAT or PROD"
fi
echo "sleeping for 30 seconds"
sleep 30

#!/bin/bash

SourceDBInstanceIdentifier=$1
DBInstanceIdentifier=$2 
region=$3
Environment=$4
APP=$5

##NonProd Variables
AppID='1478EE8A-20BC-4174-BACD-35D9E61A3F73'
NP_DbSubnetGroupName='uat-rds-new-private-subnet-group'    ###'uat-usw2-pvt-subnet-group'###
NP_DBParameterGroupName='beta-usw2-care-param-oracle'
NP_VPCSecurityGroupIds='sg-021d935484a5770b7'
NP_KMSKeyId='567a53fa-2370-4e99-9398-ac7a07245b0e'
NP_PerformanceInsightsKmsKeyId='arn:aws:kms:us-west-2:699183880494:key/567a53fa-2370-4e99-9398-ac7a07245b0e'
NP_MonitoringRoleArn='arn:aws:iam::699183880494:role/rds-monitoring-role'
MaxAllocatedStorage=2000
MonitoringInterval=60
PerformanceInsightsRetentionPeriod=7


###PROD Variables
P_DbSubnetGroupName='dr-usw2-priv-rds-subnet-group-01'     ###'dr1-db-subnet-group-01'###
P_DBParameterGroupName='dr-care-param-oracle'
P_VPCSecurityGroupIds='sg-08957410cae0558a8'
P_KMSKeyId='54058ae8-1bd9-4522-84c9-d09e6b4486a0'
P_MonitoringRoleArn='arn:aws:iam::897860998156:role/Prod-RDS-EnhanceMonitoring-Role'
P_PerformanceInsightsKmsKeyId='arn:aws:kms:us-west-2:897860998156:key/54058ae8-1bd9-4522-84c9-d09e6b4486a0'



sourcedbinstanceidentifierarn=$(aws rds describe-db-instances --db-instance-identifier  ${SourceDBInstanceIdentifier} | grep -w "DBInstanceArn" | awk '{ print $2}' | tr -d '",')

if [ -z ${source-db-instance-identifier} ]
then
   echo "${source-db-instance-identifier} is source-db-instance-identifier value, seems empty so coming out of $(basename $0)"
   exit
fi

if [ -z ${db-instance-identifier} ]
then
   echo "${db-instance-identifier} is db-instance-identifier variable value, seems empty so coming out of $(basename $0)"
   exit
fi

if [ -z ${region} ]
then
   echo "${region} is region variable value, seems empty so coming out of $(basename $0)"
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

##Creating the read replica for Oracle-ee in Oregon with tags
if [ $Environment == "BETA" -o $Environment == "beta" ]
then
    echo " Environment is $Environment "
    aws rds create-db-instance-read-replica --db-instance-identifier ${DBInstanceIdentifier} --source-db-instance-identifier ${sourcedbinstanceidentifierarn} --replica-mode open-read-only  --source-region ${region} --db-subnet-group-name ${NP_DbSubnetGroupName}  --vpc-security-group-ids ${NP_VPCSecurityGroupIds} --db-parameter-group-name  ${NP_DBParameterGroupName} --kms-key-id ${NP_KMSKeyId}  --region us-west-2 --multi-az --max-allocated-storage ${MaxAllocatedStorage} --enable-cloudwatch-logs-exports "alert" "audit" "listener" "trace"  --enable-performance-insights --performance-insights-retention-period ${PerformanceInsightsRetentionPeriod} --performance-insights-kms-key-id ${NP_PerformanceInsightsKmsKeyId} --monitoring-interval ${MonitoringInterval} --monitoring-role-arn ${NP_MonitoringRoleArn}  --tags "[{\"Key\": \"Owner\",\"Value\": \"${APP}\"},{\"Key\": \"AppID\",\"Value\": \"${AppID}\"},{\"Key\": \"Environment\",\"Value\": \"${Environment}\"},{\"Key\": \"BU\",\"Value\": \"DJI\"},{\"Key\": \"UsedFor\",\"Value\": \"Oracle Database\"}]"

elif [ $Environment == "PROD" -o $Environment == "prod" ]
then 
     echo " Environment is $Environment "
     aws rds create-db-instance-read-replica --db-instance-identifier ${DBInstanceIdentifier} --source-db-instance-identifier ${sourcedbinstanceidentifierarn} --replica-mode open-read-only  --source-region ${region} --db-subnet-group-name ${P_DbSubnetGroupName}  --vpc-security-group-ids ${P_VPCSecurityGroupIds} --db-parameter-group-name  ${P_DBParameterGroupName} --kms-key-id ${P_KMSKeyId}  --region us-west-2 --multi-az --max-allocated-storage ${MaxAllocatedStorage} --enable-cloudwatch-logs-exports "alert" "audit" "listener" "trace" --enable-performance-insights --performance-insights-retention-period ${PerformanceInsightsRetentionPeriod} --performance-insights-kms-key-id ${P_PerformanceInsightsKmsKeyId} --monitoring-interval ${MonitoringInterval} --monitoring-role-arn ${P_MonitoringRoleArn} --tags "[{\"Key\": \"Owner\",\"Value\": \"${APP}\"},{\"Key\": \"AppID\",\"Value\": \"${AppID}\"},{\"Key\": \"Environment\",\"Value\": \"${Environment}\"},{\"Key\": \"BU\",\"Value\": \"DJI\"},{\"Key\": \"UsedFor\",\"Value\": \"Oracle Database\"}]"
else
    echo " Environment is $Environment "
    echo "environment should be either BETA or PROD"
fi
echo "sleeping for 30 seconds"
sleep 30

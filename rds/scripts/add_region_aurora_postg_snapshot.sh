#!/bin/bash

DRDBClusterIdentifier=${1}
DRDBInstanceIdentifier=${2}
DRDBInstanceIdentifier2=${3}
stackname=${4}
region=${5}
envapp=${6}
Environment=${7}
APP=${8}
AppID=${9}
Build_Number=${10}
PDBClusterIDN=${11}
GlobalClusterName=${12}


##below are required for dr_addregion_tags.sh tags script 
export Environment
export APP
export region
export PDBClusterIDN
export GlobalClusterName
UsedFor=RDS
BU=DJI
BackupRetentionPeriod=3
PerformanceInsightsRetentionPeriod=7
P_PerformanceInsightsKmsKeyId='arn:aws:kms:us-west-2:897860998156:key/54058ae8-1bd9-4522-84c9-d09e6b4486a0'


#cd /local/apps/jenkins/scripts

#sfilename=${envapp}.cfvars.addregion.txt
primaryclsvars=${envapp}.cfvars.addregion-${Build_Number}.sh


echo "Executing python cf script to get the Outputs and Parameters and put into a file"

echo "$PWD is pwd before executing prod_mdb_aurora_postg_addregion_cf.py"

sudo chmod +x prod_mdb_aurora_postg_addregion_cf.py
./prod_mdb_aurora_postg_addregion_cf.py $stackname $region $envapp $Build_Number

if [ -f $primaryclsvars ]
then
    cat $primaryclsvars
else
     echo "primaryclsvars file is not existing so coming out of Add region script"
     exit
fi


chmod +x $primaryclsvars
#sed -i 's/:/=/g'  $dfilename

. ./$primaryclsvars       ###has GlobalClusterName DBEngine_Version DBInstanceClass DBEngine

if [ -z $DRDBClusterIdentifier ]
then
   echo "$DRDBClusterIdentifier is DRDBClusterIdentifier variable value, seems empty so coming out of $(basename $0)"
   exit
fi

if [ -z $GlobalClusterName ]
then
   echo "$GlobalClusterName is GlobalClusterName variable value, seems empty so coming out of $(basename $0)"
   exit
fi

if [ -z $DBEngine ]
then
   echo "$DBEngine is DBEngine variable value, seems empty so coming out of $(basename $0)"
   exit
fi

if [ -z $DBEngine_Version ]
then
   echo "$DBEngine_Version is DBEngine_Version variable value, seems empty so coming out of $(basename $0)"
   exit
fi


#APP=CIP   ###temporary

echo "$APP is APP and $Environment is Environment in Addregion script"

###--db-cluster-parameter-group-name seletion
if [ $APP == CIP -a $Environment == PREPROD ]
then
  dr_db_cluster_param_aurorapostgresql=preprod-cip-cluster-param-aurapostgres
  echo "$dr_db_cluster_param_aurorapostgresql is dr_db_cluster_param_aurorapostgresql "
elif [ $APP == CIP -a $Environment == PROD ]
then
  dr_db_cluster_param_aurorapostgresql=dr-cip-cluster-param-aurapostgres
  echo "$dr_db_cluster_param_aurorapostgresql is dr_db_cluster_param_aurorapostgresql "
elif [ $APP == MDB -a $Environment == PREPROD ]
then
  dr_db_cluster_param_aurorapostgresql=predr-mdb-cluster-param-aurapostgres
  echo "$dr_db_cluster_param_aurorapostgresql is dr_db_cluster_param_aurorapostgresql "
elif [ $APP == MDB -a $Environment == PROD ]
then
  dr_db_cluster_param_aurorapostgresql=dr-mdb-cluster-param-aurapostgres
  echo "$dr_db_cluster_param_aurorapostgresql is dr_db_cluster_param_aurorapostgresql "
elif [ $APP == IDX -a $Environment == DR ]
then
  dr_db_cluster_param_aurorapostgresql=dr-idx-cluster-paramet-aurapostgres12
  echo "$dr_db_cluster_param_aurorapostgresql is dr_db_cluster_param_aurorapostgresql "
elif [ $APP == IDX -a $Environment == PROD ]
then
  dr_db_cluster_param_aurorapostgresql=dr-idx-cluster-paramet-aurapostgres12
  echo "$dr_db_cluster_param_aurorapostgresql is dr_db_cluster_param_aurorapostgresql "
else
   echo "conditional checks fialed for db cluster parameter groups"
fi


###dr_db_paramgroup_aurorapostgresql
if [ $APP == CIP -a $Environment == PREPROD ]
then
  dr_db_paramgroup_aurorapostgresql=preprod-cip-param-aurapostgres
  echo "$dr_db_paramgroup_aurorapostgresql is dr_db_paramgroup_aurorapostgresql "
elif [ $APP == CIP -a $Environment == PROD ]
then
  dr_db_paramgroup_aurorapostgresql=dr-cip-param-aurapostgres
  echo "$dr_db_paramgroup_aurorapostgresql is dr_db_paramgroup_aurorapostgresql "
elif [ $APP == MDB -a $Environment == PREPROD ]
then
  dr_db_paramgroup_aurorapostgresql=predr-mdb-param-aurapostgres
  echo "$dr_db_paramgroup_aurorapostgresql is dr_db_paramgroup_aurorapostgresql "
elif [ $APP == MDB -a $Environment == PROD ]
then
  dr_db_paramgroup_aurorapostgresql=dr-mdb-param-aurapostgres
  echo "$dr_db_paramgroup_aurorapostgresql is dr_db_paramgroup_aurorapostgresql "
elif [ $APP == IDX -a $Environment == DR ]
then
  dr_db_paramgroup_aurorapostgresql=dr-idx-database-paramet-aurapostgres12
  echo "$dr_db_paramgroup_aurorapostgresql is dr_db_paramgroup_aurorapostgresql "
elif [ $APP == IDX -a $Environment == PROD ]
then
  dr_db_paramgroup_aurorapostgresql=dr-idx-database-paramet-aurapostgres12
  echo "$dr_db_paramgroup_aurorapostgresql is dr_db_paramgroup_aurorapostgresql "
else
   echo "conditional checks fialed for db cluster parameter groups"
fi

#APP=INFRA
#export APP
#echo "$APP  is temporary APP"

##### DB Subnetgroup selection
if [ $Environment == PREPROD ]
then
  db_subnet_group_name=preprod-usw2-priv-subnet-group    ##preprod-dr1-db-subnet-group-01
  echo "$db_subnet_group_name is db_subnet_group_name "
elif [ $Environment == PROD ]
then
  db_subnet_group_name=dr-usw2-priv-rds-subnet-group-01    ##dr1-db-subnet-group-01
  echo "$db_subnet_group_name is db_subnet_group_name "
else
   echo "conditional checks fialed for db_subnet_group_name"
fi

##### West Region Security group selection
if [ $Environment == PREPROD ]
then
  security_group_id=sg-0f0b19e7d2f2ba18b
  echo "$security_group_id is security_group_id "
elif [ $Environment == PROD ]
then
  security_group_id=sg-08957410cae0558a8
  echo "$security_group_id is security_group_id "
else
   echo "conditional checks fialed for security_group_id"
fi

if [ $APP == IDX -o $APP == idx ]
then
   APP=ARROW
   echo "For IDX RDS changing the Owner Tag to ARROW"
   export APP
fi

###Create GlobalCluster to an existing Regional Cluster
echo "Create GlobalCluster to an existing Regional Cluster created from RDS Snapshot"

echo "$PDBClusterIDN is PDBClusterIDN"
PDBClusterARN=$(/usr/local/bin/aws rds describe-db-clusters --db-cluster-identifier $PDBClusterIDN --region us-east-1 | grep -w "DBClusterArn" | awk '{print $2}' | tr -d "," | xargs)
export PDBClusterARN
echo "$PDBClusterARN is PDBClusterARN"
echo "$GlobalClusterName is GlobalClusterName"
/usr/local/bin/aws rds create-global-cluster --region us-east-1 --global-cluster-identifier $GlobalClusterName --source-db-cluster-identifier $PDBClusterARN

echo "sleep for 3m"
sleep 3m
#sleep 3
##check Global Cluster status
#GCStatus=$(aws rds describe-global-clusters --region us-east-1 --global-cluster-identifier $GlobalClusterName --query "GlobalClusters[0].Status" | xargs)
#echo "$GCStatus is the status of GlobalCluster before Secondary Cluster Creation"

##check Primary Cluster status 
#PCStatus=$(aws rds describe-db-clusters --region us-east-1 --db-cluster-identifier $PDBClusterIDN --query  "DBClusters[0].Status" | xargs)
#echo "$PCStatus is the status of Primary Cluster before Secondary Cluster Creation"

#if [[ $GCStatus == 'available' && $PCStatus == 'available' ]]
#then

echo "Creating Secondary Cluster in Oregon Region "
/usr/local/bin/aws rds --region us-west-2 create-db-cluster --deletion-protection --copy-tags-to-snapshot --backup-retention-period $BackupRetentionPeriod --preferred-backup-window  03:00-04:00 --preferred-maintenance-window sat:04:01-sat:08:00 --db-cluster-identifier  $DRDBClusterIdentifier --global-cluster-identifier $GlobalClusterName --engine $DBEngine --engine-version $DBEngine_Version --db-subnet-group-name $db_subnet_group_name --vpc-security-group-ids $security_group_id --db-cluster-parameter-group-name $dr_db_cluster_param_aurorapostgresql --kms-key-id alias/rds-dr-oregon-key1 --source-region us-east-1 --tags "[{\"Key\": \"Owner\",\"Value\": \"$APP\"},{\"Key\": \"Build_Number\",\"Value\": \"$Build_Number\"},{\"Key\": \"AppID\",\"Value\": \"$AppID\"},{\"Key\": \"Environment\",\"Value\": \"$Environment\"},{\"Key\": \"BU\",\"Value\": \"$BU\"},{\"Key\": \"UsedFor\",\"Value\": \"$UsedFor\"}]"

#else
#   echo "Coming out of script as GlobalCluster or Primary Cluster status is not available."
#   exit 1
#fi

echo "Sleep for 12m"
sleep 12m

if [ -z $DBInstanceClass ]
then
   echo "$DBInstanceClass is DBInstanceClass variable value, seems empty so coming out of $(basename $0)"
   exit
fi

if [ -z $DRDBInstanceIdentifier ]
then
   echo "$DRDBInstanceIdentifier is DRDBInstanceIdentifier variable value, seems empty so coming out of $(basename $0)"
   exit
fi

if [ -z $DRDBInstanceIdentifier2 ]
then
   echo "$DRDBInstanceIdentifier2 is DRDBInstanceIdentifier2 variable value, seems empty so coming out of $(basename $0)"
   exit
fi

##check Secondary Cluster status 
#SCStatus=$(aws rds describe-db-clusters --region us-west-2 --db-cluster-identifier $DRDBClusterIdentifier --query  "DBClusters[0].Status" | xargs)
#echo "$SCStatus is the status of Secondary Cluster before Associating 1st and 2nd DB Instances"

#if [ $SCStatus == 'available' ]
#then
  
echo "Associating First Instnaces in Secondary Cluster"
/usr/local/bin/aws rds --region us-west-2 create-db-instance --enable-performance-insights --performance-insights-retention-period ${PerformanceInsightsRetentionPeriod} --performance-insights-kms-key-id ${P_PerformanceInsightsKmsKeyId} --preferred-maintenance-window sat:04:01-sat:08:00 --db-instance-class  $DBInstanceClass --db-cluster-identifier $DRDBClusterIdentifier --db-instance-identifier $DRDBInstanceIdentifier --engine $DBEngine --engine-version $DBEngine_Version --db-parameter-group-name $dr_db_paramgroup_aurorapostgresql --tags "[{\"Key\": \"Owner\",\"Value\": \"$APP\"},{\"Key\": \"AppID\",\"Value\": \"$AppID\"},{\"Key\": \"Environment\",\"Value\": \"$Environment\"},{\"Key\": \"BU\",\"Value\": \"$BU\"},{\"Key\": \"UsedFor\",\"Value\": \"$UsedFor\"}]"

echo "sleeping for 3m"
sleep 3m

echo "Associating Second Instnaces in Secondary Cluster"
/usr/local/bin/aws rds --region us-west-2 create-db-instance --enable-performance-insights --performance-insights-retention-period ${PerformanceInsightsRetentionPeriod} --performance-insights-kms-key-id ${P_PerformanceInsightsKmsKeyId} --preferred-maintenance-window sat:04:01-sat:08:00 --db-instance-class  $DBInstanceClass --db-cluster-identifier $DRDBClusterIdentifier --db-instance-identifier $DRDBInstanceIdentifier2 --engine $DBEngine --engine-version $DBEngine_Version --db-parameter-group-name $dr_db_paramgroup_aurorapostgresql --tags "[{\"Key\": \"Owner\",\"Value\": \"$APP\"},{\"Key\": \"AppID\",\"Value\": \"$AppID\"},{\"Key\": \"Environment\",\"Value\": \"$Environment\"},{\"Key\": \"BU\",\"Value\": \"$BU\"},{\"Key\": \"UsedFor\",\"Value\": \"$UsedFor\"}]"

#else
    #echo "$SCStatus status seems not available, so coming out of script"
    #exit 1
#fi 

echo "sleeping for 5m"
sleep 5m

##Wait for Seconary Cluster RDS Reader Instance Available status.
chmod +x ORRDSInstancestatus.sh
./ORRDSInstancestatus.sh $DRDBInstanceIdentifier2

#if [[ -n $envapp && -n $Build_Number && -n $GlobalClusterName ]]
#then
   #echo "updating prod spdji-rds-inventory DynamoDB table with ClusterName"
   #./UpdateBuildState.py  AppName=$envapp  BuilID=$Build_Number ClusterName=$GlobalClusterName
#else
   #echo "seems envapp or buildid or GlobalClusterName one of them are empty, So skipping dynamoDB table update"
#fi

##tags inclusion to the DB Instances
#sudo chmod +x dr_addregion_tags.sh
#./dr_addregion_tags.sh $DRDBInstanceIdentifier $DRDBInstanceIdentifier2

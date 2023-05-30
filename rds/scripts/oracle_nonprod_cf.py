#!/usr/libexec/platform-python
import boto3
import sys
import os
import time

#os.chdir('/local/apps/jenkins/scripts')
#cwd=os.getcwd()
#print(f"current working directory is: {cwd}")

region=sys.argv[2]
##envapp will be sys.argv[3]
name=sys.argv[3]
filename="%s.cfvars.txt" % name

replicadbindentifier=sys.argv[4]

cf_client=boto3.client(service_name='cloudformation',region_name=region)
cf_stack=cf_client.describe_stacks(StackName=sys.argv[1])
rds_client=boto3.client(service_name='rds',region_name='us-west-2')

rds_response=rds_client.describe_db_instances(DBInstanceIdentifier=replicadbindentifier)

object=open(filename,"w")

for item in cf_stack['Stacks']:
    for new_item in item['Parameters']:
        if new_item['ParameterKey']=='Engine':
             DBEngine=new_item['ParameterValue']
             object.write(f"DBEngine:{DBEngine}\n")
        elif new_item['ParameterKey']=='MultiAZ':
             MultiAZ=new_item['ParameterValue']
             object.write(f"MultiAZ:  {MultiAZ}\n")
        elif new_item['ParameterKey']=='EngineVersion':
             DBEngine_Version=new_item['ParameterValue']
             object.write(f"DBEngine_Version:{DBEngine_Version}\n")
        elif new_item['ParameterKey']=='DBInstanceClass':
             DBInstanceClass=new_item['ParameterValue']
             object.write(f"DBInstanceClass:{DBInstanceClass}\n")



for item1 in cf_stack['Stacks']:
   for newitem in item1['Outputs']:
      #if newitem['OutputKey'] == 'ReaderEndpoint':
          #PrimaryReaderEndpoint=newitem['OutputValue']
          #object.write(f"PrimaryReaderEndpoint:{PrimaryReaderEndpoint}\n")
      #elif newitem['OutputKey']=='GlobalClusterName':
           #GlobalClusterName=newitem['OutputValue']
           #object.write(f"GlobalClusterName:{GlobalClusterName}\n")
      #elif newitem['OutputKey'] == 'ClusterEndpoint':
           #PrimaryClusterEndpoint=newitem['OutputValue']
           #object.write(f"PrimaryClusterEndpoint:{PrimaryClusterEndpoint}\n")
      if newitem['OutputKey'] == 'EndPoint':
           EndPoint=newitem['OutputValue']
           object.write(f"EndPoint:{EndPoint}\n")
      elif newitem['OutputKey'] == 'InstanceName':
           InstanceName=newitem['OutputValue']
           object.write(f"InstanceName:{InstanceName}\n")
      #elif newitem['OutputKey'] == 'ClusterName':
           #ClusterName=newitem['OutputValue']
           #object.write(f"ClusterName:  {ClusterName}\n")

        
while True:

     rds_client=boto3.client(service_name='rds',region_name='us-west-2')
     rds_response=rds_client.describe_db_instances(DBInstanceIdentifier=replicadbindentifier)
     #endpoint= [ sub['Endpoint'] for sub in rds_response['DBInstances']]
     endpoint=any('Endpoint' in d for d in rds_response['DBInstances'])
     print(endpoint)
     if endpoint:
        break
     else:
          print("Waiting for the Replica DB identifier Endpoint value")
          time.sleep(60)

print("waiting completed for Replica DB Identifier Endpoint value")

rds_client=boto3.client(service_name='rds',region_name='us-west-2')
rds_response=rds_client.describe_db_instances(DBInstanceIdentifier=replicadbindentifier)

for item in rds_response['DBInstances']:
        ReplicaEndPoint=item['Endpoint']['Address']
        object.write(f"ReplicaEndPoint:{ReplicaEndPoint}\n")
        ReplicaDBInstanceIdentifier=item['DBInstanceIdentifier']
        object.write(f"ReplicaDBInstanceIdentifier:{ReplicaDBInstanceIdentifier}\n")
        ReplicaMode=item['ReplicaMode']
        object.write(f"ReplicaMode:{ReplicaMode}\n")
        ReplicaDBInstanceArn=item['DBInstanceArn']
        object.write(f"ReplicaDBInstanceArn:{ReplicaDBInstanceArn}\n")

object.close()

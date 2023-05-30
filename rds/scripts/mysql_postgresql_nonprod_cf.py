#!/usr/bin/python3.8
import boto3
import sys
import os

#os.chdir('/local/apps/jenkins/scripts')
#cwd=os.getcwd()
#print(f"current working directory is: {cwd}")

region=sys.argv[2]
##envapp will be sys.argv[3]
name=sys.argv[3]
buildnumber=sys.argv[4]
filename="%s.cfvars.%s.txt" % (name,buildnumber)


cf_client=boto3.client(service_name='cloudformation',region_name=region)
cf_stack=cf_client.describe_stacks(StackName=sys.argv[1])


object=open(filename,"w")

for item in cf_stack['Stacks']:
    for new_item in item['Parameters']:
        if new_item['ParameterKey']=='MultiAZ':
           MultiAZ=new_item['ParameterValue']
           object.write(f"MultiAZ:  {MultiAZ}\n")
        elif new_item['ParameterKey']=='Engine':
             DBEngine=new_item['ParameterValue']
             object.write(f"DBEngine:  {DBEngine}\n")
        elif new_item['ParameterKey']=='EngineVersion':
             DBEngine_Version=new_item['ParameterValue']
             object.write(f"DBEngine_Version:  {DBEngine_Version}\n")
        #elif new_item['ParameterKey']=='DBClusterIdentifier':
             #ClusterName=new_item['ParameterValue']
             #object.write(f"ClusterName:  {ClusterName}\n")   


for item1 in cf_stack['Stacks']:
   for newitem in item1['Outputs']:
      if newitem['OutputKey'] == 'ReaderEndpoint':
          ReaderEndpoint=newitem['OutputValue']
          object.write(f"ReaderEndpoint:  {ReaderEndpoint}\n")
      if newitem['OutputKey']=='EndPoint':
           EndPoint=newitem['OutputValue']
           object.write(f"EndPoint:  {EndPoint}\n")
      elif newitem['OutputKey'] == 'ClusterEndpoint':
           ClusterEndpoint=newitem['OutputValue']
           object.write(f"ClusterEndpoint:  {ClusterEndpoint}\n")
      elif newitem['OutputKey'] == 'InstanceName':
           InstanceName=newitem['OutputValue']
           object.write(f"InstanceName:  {InstanceName}\n")
      elif newitem['OutputKey'] == 'ClusterName':
           ClusterName=newitem['OutputValue']
           object.write(f"ClusterName:  {ClusterName}\n")

object.close()

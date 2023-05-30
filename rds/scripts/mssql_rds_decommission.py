#!/usr/bin/python3.8

import os
import boto3
from pprint import pprint
import sys
from re import search
import time
import subprocess

arglen=len(sys.argv)
if arglen < 7:
   print("Need Parameters: Environment  Owner  Build_Number  ENVAPP  Current_Build_Number  Decom_user_Mail_ID")
   sys.exit()

def runcommand (cmd):
    proc = subprocess.Popen(cmd,
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE,
                            shell=True,
                            universal_newlines=True)
    std_out, std_err = proc.communicate()
    return proc.returncode, std_out, std_err
   
env=sys.argv[1]
owner=sys.argv[2]
buildnum=sys.argv[3]           #user inputed build number

envapp=sys.argv[4]
Build_Number=sys.argv[5]       ###current build ID
Decom_Mail_ID=sys.argv[6]          


os.chdir("rds")
cwd=os.getcwd()
print(f"current working directory is: {cwd}")

filename=envapp+".cfvars."+buildnum+".txt"
if os.path.exists(filename):
  os.remove(filename)

object=open(filename,"w")

dbidentifiers=[]
#object=open(filename,"w")
for region in ['us-east-1','us-west-2']:
  rdsclient=boto3.client('rds',region_name=region)
  dbinstances=rdsclient.describe_db_instances()['DBInstances']
  #pprint(dbinstances)
  for dbinstance in dbinstances:
    dbinstid=""
    BuildNum=""
    Owner=""
    #print(dbinstid)
    dbinstid=dbinstance['DBInstanceIdentifier']
    for tags in dbinstance['TagList']:
        if tags['Key'] == 'Build_Number':
            BuildNum=tags['Value']
        if tags['Key'] == 'Owner':
            Owner=tags['Value']
        if tags['Key'] == 'Environment':
            Environment=tags['Value']
    if BuildNum == buildnum and Owner == owner and Environment == env:
            #print(dbinstid)
            dbidentifiers.append(dbinstid)

print(dbidentifiers," DB Identifiers")
#dbids=[*set(dbidentifiers)]
#print(dbids)


if len(dbidentifiers):
  print("db identifiers are not empty")
else:
  print("db identifiers are empty so coming out of ",os.path.basename(__file__)," script, Make sure mandatory tags Owner,Environment,Build_Number are assigned")
  exit()
   
for instance in dbidentifiers:
     if 'usw2' in instance or 'replica' in instance:
        replicadbidentifier=instance
        object.write(f"Replica DB Identifier:  {replicadbidentifier}\n")
        if search("usw2",replicadbidentifier):
            replicaregion = 'us-west-2'
        elif search("use1",replicadbidentifier):
            replicaregion= 'us-east-1'

        print(replicaregion," is replica db region")
      
        print(replicadbidentifier," is Replica DB Identifier before deletion")
        rdsclient=boto3.client('rds',region_name=replicaregion)
        try:
          rdsclient.modify_db_instance(DBInstanceIdentifier=replicadbidentifier,DeletionProtection=False)
          rdsclient.delete_db_instance(DBInstanceIdentifier=replicadbidentifier,SkipFinalSnapshot=True,DeleteAutomatedBackups=True)
          print("Sleeping for 150 secs...")
          time.sleep(150)

          dbidentifiers.remove(replicadbidentifier)
        except Exception as e:
            print(e)
            
        

print(dbidentifiers)
for instance in dbidentifiers:
     if 'use1' in instance and 'replica' not in instance:
        primarydbidentifier=instance
        object.write(f"Primary DB Identifier:  {primarydbidentifier}\n")
        if search("usw2",primarydbidentifier):
            sourceregion = 'us-west-2'
        elif search("use1",primarydbidentifier):
            sourceregion= 'us-east-1'

        print(sourceregion," is source db region")
         
        print(primarydbidentifier," Primary DB Identifier before deletion")
        rdsclient=boto3.client('rds',region_name=sourceregion)
        try:
          rdsclient.modify_db_instance(DBInstanceIdentifier=primarydbidentifier,DeletionProtection=False)
          rdsclient.delete_db_instance(DBInstanceIdentifier=primarydbidentifier,SkipFinalSnapshot=True,DeleteAutomatedBackups=True)
      
          print("Sleeping for 150 secs...")
          time.sleep(150)
        except Exception as e:
          print(e)
      
#if [[ -n $envapp && -n $Build_Number && -n $Decom_Mail_ID ]]
#then
   #echo "updating prod spdji-rds-inventory DynamoDB table with mail id of who deleted RDS"
   #./rds/UpdateBuildState.py  AppName=$envapp  BuilID=$Build_Number Decommission_User_MailID=$Decom_Mail_ID
#else
   #echo "seems envapp or buildid or Decom_Mail_ID one of them are empty, So skipping dynamoDB table update"
#fi

object.close()

os.chdir("..")
cwd=os.getcwd()
print(f"current working directory is: {cwd}")

if bool(envapp) == True and bool(Build_Number) == True and bool(Decom_Mail_ID) == True and bool(buildnum) == True:
  
    cmd = 'sudo ./rds/UpdateBuildState.py AppName='+ envapp +' BuilID='+ buildnum +' Decommission_User_MailID='+ Decom_Mail_ID +' Decommission_Build_Number='+ Build_Number
    code,output,error = runcommand(cmd)
    print(code)
    print(output)
    print(error)
    
    if code != 0:
        print (error)
        sys.exit(error)

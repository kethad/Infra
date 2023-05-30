#!/usr/libexec/platform-python
import json
import boto3
import sys
ArgLen=len(sys.argv)
if ArgLen < 3:
    print ("Need Parameters: AppName BuildID")
    sys.exit()
dbitem={}
APPNAME=sys.argv[1]
BUILDID=sys.argv[2]
if ArgLen == 4:
    ReqKey = sys.argv[3]
else:
    ReqKey=""
dynamodb = boto3.client(service_name='dynamodb',region_name='us-east-1')
response=dynamodb.query(
    ExpressionAttributeValues={
        ':app': {
            'S': APPNAME,
        },
        ':buildid': {
            'S': BUILDID,
        }
    },
    KeyConditionExpression='AppName = :app AND BuildID = :buildid',
    TableName='spdji-rds-inventory',
)

PrntStrng=""
for items in response['Items']:
    ResponseKeys=items.keys()
    for kys in ResponseKeys:
        vls=list(items[kys].values())[0]
        if kys == "IP" or kys == "INST_ID" or kys == 'LB_R53RECORD' or kys == 'HOST_R53RECORD' or kys == 'LB_R53ZONE' or kys == 'HOST_R53ZONE' or kys == 'LB_WT_VAL' or kys == 'LB_WT_ID':
            ipinstvls=""
            for IPSINSTS  in vls:
                if  isinstance(IPSINSTS,dict):
                    if ipinstvls == "":
                        if IPSINSTS['S'] == "Ignore":
                            ipinstvls=""
                            continue
                        else:
                            ipinstvls=IPSINSTS['S']
                    else:
                        ipinstvls=ipinstvls + "," + IPSINSTS['S']
                else:
                    if ipinstvls == "":
                        ipinstvls=IPSINSTS
                    else:
                        ipinstvls=ipinstvls + "," + IPSINSTS
            vls=ipinstvls
        if ReqKey == kys:
            print (vls)
        if PrntStrng == "":
            PrntStrng= kys + ": " + vls
        else:
            PrntStrng=PrntStrng + "\n" + kys + ": " + vls

if ArgLen == 3:
    print (PrntStrng)

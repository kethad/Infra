#!/usr/libexec/platform-python
import boto3
import sys
ArgLen=len(sys.argv)
if ArgLen < 3:
    print ("Need Parameters: AppName=<app id> Mode=<RW/RO> DNSName=<Name of the DNS Record>")
    sys.exit()
dynamodb = boto3.client(service_name='dynamodb',region_name='us-east-1')
PKEY=sys.argv[1].split("=")[1]
SKEY=sys.argv[2].split("=")[1]
Table="spdji-rds-dns-inventory"
if ArgLen == 3:
    dynamodb.put_item(
    TableName=Table,
    Item={  'AppName': {'S': PKEY },
            'Mode': {'S': SKEY }
         }
)
else:
    cntr=0
    #dynamodb.put_item(
    #TableName=Table,
    #Item={  'AppName': {'S': PKEY },
    #        'Mode': {'S': SKEY }
    #     }
    #)
    for item in sys.argv:
        #print item
        if cntr == 0 or cntr == 1 or cntr == 2:
            cntr=cntr + 1
            continue
        key=item.split("=")[0]
        value=item.split("=")[1]
        print (key,value)
        dynamodb.update_item (
            TableName=Table,
            Key={
                'AppName': {'S': PKEY },
                'Mode': {'S': SKEY }
            },
            UpdateExpression="SET #k=:v",
            ExpressionAttributeNames={
                '#k' : key
            },
            ExpressionAttributeValues={
                ':v': {"S": value}
                }
            )

    cntr=cntr + 1

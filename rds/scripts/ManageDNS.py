#!/bin/python
import boto3
import sys
import os
import json
import getpass
import socket
from optparse import OptionParser
from botocore.exceptions import ClientError 
import signal #import imp
#imp.load_source("reportRoute53Records",'/local/apps/infra/scripts/inventory/reportRoute53Records.py')
def signal_handler(sig, frame):
        print("\nUser Aborted!\n")
        if os.path.exists(DBFile):
            os.remove(DBFile)
        sys.exit(0)
signal.signal(signal.SIGINT, signal_handler) #print('Press Ctrl+C')
#signal.pause()
def toBool(STR):
    if STR == 'True':
        return True
    else:
        return False
        
DBFile="/tmp/AWS_R53_Prod.csv"
parser = OptionParser(usage="usage: %prog show <DNS Name>\nusage: %prog update <DNS Name> <New Primary Value>") #parser.add_option("-b",
                      #action="store", # optional because action defaults to "store"
                      #dest="Target",
                      #nargs=1,
                      #help="usage: %prog <options> <start/stop/status> <IP Addresses>",) 
(options, args) = parser.parse_args()
#args=parser.parse_args()
if not args or len(args) < 2:
    print len(args)
    parser.print_usage()
    if os.path.exists(DBFile):
            os.remove(DBFile)
    sys.exit()
elif args[0] == 'update' and len(args) < 3:
    parser.print_usage()
    if os.path.exists(DBFile):
            os.remove(DBFile)
    sys.exit()
#elif args[1] == 'update' and len(args) < 3:
 #   print "Upate requires new primary value\n"
  #  parser.print_usage()
   # print "<New Primary Value>\n"
else:
    DNSName=args[1]
    

if "dr.spindices.com" in DNSName:
    stsclient = boto3.client('sts')
    stsresponse = stsclient.assume_role(
        RoleArn='arn:aws:iam::210265922058:role/DR-EC2-INFRA',
        RoleSessionName='Jenkins-DNS-Job',
        )
    ACCESSKEY=stsresponse['Credentials']['AccessKeyId']
    SECRETKEY=stsresponse['Credentials']['SecretAccessKey']
    TOKEN=stsresponse['Credentials']['SessionToken']
    client = boto3.client('route53',aws_access_key_id=ACCESSKEY,aws_secret_access_key=SECRETKEY,aws_session_token=TOKEN)
    os.system("./rds/reportRoute53Records_dr.py >/dev/null")
else:
    client = boto3.client('route53')
    os.system("./rds/reportRoute53Records.py >/dev/null")

ResultSET={
            "ZONEID": "",
            "RecordName": "",
            "RecordType": "",
            "TTL": "",
            "PrimaryRecord": "",
            "SecondaryRecords": []
        }    
with open(DBFile,'r') as Input:
    for Line in Input:
        #print Line
        ZONEID=Line.split(',')[1]
        RecordName=Line.split(',')[2]
        RecordType=Line.split(',')[3]
        RecordValue=Line.split(',')[4]
        RecWeight=Line.split(',')[5].rstrip("\n")
        Alias=Line.split(',')[6].rstrip("\n")
        AliasZoneID=Line.split(',')[7].rstrip("\n")
        AliasEvalHealth=Line.split(',')[8].rstrip("\n")
        RecordSetID=Line.split(',')[9].rstrip("\n")
        RecTTL=Line.split(',')[10].rstrip("\n")
        if RecordName == DNSName + ".":
            if RecWeight != '':
                ResultSET['ZONEID']=ZONEID
                ResultSET['RecordName']=RecordName
                ResultSET['RecordType']=RecordType
                ResultSET['TTL']=RecTTL
                RecordWeight=RecWeight
                if RecWeight == "255":
                    ResultSET['PrimaryRecord']=RecordValue + ":" + Alias + ":" + AliasZoneID + ":" + AliasEvalHealth + ":" + RecordSetID
                else:
                    ResultSET['SecondaryRecords'].append(RecordValue + ":" + Alias + ":" + AliasZoneID + ":" + AliasEvalHealth + ":" + RecordSetID)
            else:
                RecordWeight=""
                ResultSET['ZONEID']=ZONEID
                ResultSET['RecordName']=RecordName
                ResultSET['RecordType']=RecordType
                ResultSET['TTL']=RecTTL
                ResultSET['PrimaryRecord']=RecordValue + ":" + Alias + ":" + AliasZoneID + ":" + AliasEvalHealth + ":" + RecordSetID
                
if ResultSET['RecordName'].rstrip('.') == "":
    print "\nNo Weighted Record Found. Please check the DNS Name\n"
    if os.path.exists(DBFile):
            os.remove(DBFile)
    sys.exit()
if args[0] == 'show':
    print "\nDNS Name: {0} \n".format(ResultSET['RecordName'].rstrip('.'))
    print "Primary Record: {0} \n".format(ResultSET['PrimaryRecord'].split(':')[0].rstrip('.'))
    if ResultSET['SecondaryRecords']:
        secreclinepr=""
        for item in ResultSET['SecondaryRecords']:
            #print "{0},".format(item.split(':')[0].rstrip('.'))
            if secreclinepr == "":
		secreclinepr=item.split(':')[0].rstrip('.')
	    else:
            	secreclinepr=secreclinepr + ',' + item.split(':')[0].rstrip('.')

        print "Secondary Records: {0}".format(secreclinepr) 

if args[0] == 'update':
    NewPrimary=args[2]
    if NewPrimary == "" or NewPrimary == ResultSET['PrimaryRecord'].split(':')[0].rstrip('.'):
        print "\nNo Changes\n"
        if os.path.exists(DBFile):
                os.remove(DBFile)
        sys.exit()
    
    #elif any(NewPrimary not in SecRecList for SecRecList in ResultSET['SecondaryRecords']) and RecordWeight == "":
    elif RecordWeight == "":
        if 'rds' in NewPrimary or 'mq' in NewPrimary or 'kafka' in NewPrimary:
            print "\nUpdating New Primary to {0}\n".format(NewPrimary)
            #print "RDS/MQ records"
            SPREC=ResultSET['PrimaryRecord'].split(':')[0].rstrip('.')
            SPAType=ResultSET['PrimaryRecord'].split(':')[1]
            SPHZ=ResultSET['PrimaryRecord'].split(':')[2]
            SPEVH=toBool(ResultSET['PrimaryRecord'].split(':')[3])
            if SPAType == "Alias":
                response = client.change_resource_record_sets(
                        HostedZoneId=ResultSET['ZONEID'],
                        ChangeBatch={
                            'Comment': 'Copy Record sets',
                            'Changes': [
                                    {
                                        'Action': 'UPSERT',
                                        'ResourceRecordSet': {
                                            'Name': ResultSET['RecordName'],
                                            'Type': ResultSET['RecordType'],
                                            #'SetIdentifier': PRSETID,
                                            #'Weight': 0,
                                            'AliasTarget': {
                                            'HostedZoneId': SPHZ,
                                            'EvaluateTargetHealth': SPEVH,
                                            'DNSName': NewPrimary,


                                },

                                        }
                            }
                            ]
                            }
                            )
            else:
                response = client.change_resource_record_sets(
                        HostedZoneId=ResultSET['ZONEID'],
                        ChangeBatch={
                            'Comment': 'Copy Record sets',
                            'Changes': [
                                    {
                                        'Action': 'UPSERT',
                                        'ResourceRecordSet': {
                                            'Name': ResultSET['RecordName'],
                                            'Type': ResultSET['RecordType'],
                                            #'SetIdentifier': PRSETID,
                                            #'Weight': 0,
                                            'TTL': int(ResultSET['TTL']),
                                            'ResourceRecords': [
                                                    {
                                                        'Value': NewPrimary
                                                    }
                                                    ]

                                        }
                            }
                            ]
                            }
                            )
                
                
        else:
            print "\nThis record value is not allowed. Please check the value or reachout to Infra team\n"
            if os.path.exists(DBFile):
                os.remove(DBFile)
            sys.exit()
    else:
        if not any(NewPrimary in SecRecList for SecRecList in ResultSET['SecondaryRecords']):
            print "therecis{0}record".format(NewPrimary)
            print "\nNew value is not accepted in Weighed Record. Please check the value or reachout to Infra team\n"
            if os.path.exists(DBFile):
                os.remove(DBFile)
            sys.exit()
            
        print "\nUpdating New Primary to {0}\n".format(NewPrimary)
        AType=""
        AHZ=""
        AEVH=""
        ASETID=""
        SECREC=""
        for itemcomb  in ResultSET['SecondaryRecords']:
            SecRec=itemcomb.split(':')[0].rstrip('.')
            if SecRec == NewPrimary:
                AType=itemcomb.split(':')[1]
                AHZ=itemcomb.split(':')[2]
                AEVH=toBool(itemcomb.split(':')[3])
                ASETID=itemcomb.split(':')[4]
                SECREC=SecRec
        try:

            PRREC=ResultSET['PrimaryRecord'].split(':')[0].rstrip('.')
            PRAType=ResultSET['PrimaryRecord'].split(':')[1]
            PRHZ=ResultSET['PrimaryRecord'].split(':')[2]
            PREVH=toBool(ResultSET['PrimaryRecord'].split(':')[3])
            PRSETID=ResultSET['PrimaryRecord'].split(':')[4]
            if PRAType == "Alias":
                response = client.change_resource_record_sets(
                        HostedZoneId=ResultSET['ZONEID'],
                        ChangeBatch={
                            'Comment': 'Copy Record sets',
                            'Changes': [
                                    {
                                        'Action': 'UPSERT',
                                        'ResourceRecordSet': {
                                            'Name': ResultSET['RecordName'],
                                            'Type': ResultSET['RecordType'],
                                            'SetIdentifier': PRSETID,
                                            'Weight': 0,
                                            'AliasTarget': {
                                            'HostedZoneId': PRHZ,
                                            'EvaluateTargetHealth': PREVH,
                                            'DNSName': PRREC,


                                },

                                        }
                            }
                            ]
                            }
                            )
            else:
                response = client.change_resource_record_sets(
                        HostedZoneId=ResultSET['ZONEID'],
                        ChangeBatch={
                            'Comment': 'Copy Record sets',
                            'Changes': [
                                    {
                                        'Action': 'UPSERT',
                                        'ResourceRecordSet': {
                                            'Name': ResultSET['RecordName'],
                                            'Type': ResultSET['RecordType'],
                                            'SetIdentifier': PRSETID,
                                            'Weight': 0,
                                            'TTL': int(ResultSET['TTL']),
                                            'ResourceRecords': [
                                                    {
                                                        'Value': PRREC
                                                    }
                                                    ]

                                        }
                            }
                            ]
                            }
                            )
        except:
            pass
        if AType == "Alias":
            response = client.change_resource_record_sets(
                    HostedZoneId=ResultSET['ZONEID'],
                    ChangeBatch={
                        'Comment': 'Copy Record sets',
                        'Changes': [
                                {
                                    'Action': 'UPSERT',
                                    'ResourceRecordSet': {
                                        'Name': ResultSET['RecordName'],
                                        'Type': ResultSET['RecordType'],
                                        'SetIdentifier': ASETID,
                                        'Weight': 255,
                                        'AliasTarget': {
                                        'HostedZoneId': AHZ,
                                        'EvaluateTargetHealth': AEVH,
                                        'DNSName': SECREC


                            },

                                    }
                        }
                        ]
                        }
                        )
        else:
            response = client.change_resource_record_sets(
                    HostedZoneId=ResultSET['ZONEID'],
                    ChangeBatch={
                        'Comment': 'Copy Record sets',
                        'Changes': [
                                {
                                    'Action': 'UPSERT',
                                    'ResourceRecordSet': {
                                        'Name': ResultSET['RecordName'],
                                        'Type': ResultSET['RecordType'],
                                        'SetIdentifier': ASETID,
                                        'Weight': 255,
                                        'TTL': int(ResultSET['TTL']),
                                        'ResourceRecords': [
                                                {
                                                    'Value': SECREC
                                                }
                                                ]

                                    }
                        }
                        ]
                        }
                        )        
    
if os.path.exists(DBFile):
    os.remove(DBFile)    

# -*- coding: utf-8 -*-
"""
Inspired by python code from Kessy A
@author: markus
"""

# pip install --user suds-jurko
import os
from suds.client import Client
from suds import WebFault
from suds.plugin import MessagePlugin
from lxml import etree

def xmlpprint(xml):
    return etree.tostring(etree.fromstring(xml), pretty_print=True)

#import logging
#logging.basicConfig(level=logging.INFO)
#logging.getLogger('suds.client').setLevel(logging.DEBUG)

SVC_URL = "https://taxonattribute.artdatabankensoa.se/TaxonAttributeService.svc?wsdl"
XML_OUT = "redlistinfo.xml"

class MyPlugin(MessagePlugin):
    def __init__(self):
        self.last_sent_raw = None
        self.last_received_raw = None

    def sending(self, context):
        if context.envelope:
            self.last_sent_message = context.envelope

    def received(self, context):
        if context.reply:
            self.last_received_reply = context.reply

    def last_sent(self):
        return self.last_sent_message

    def last_received(self):
        return self.last_received_reply

plugin = MyPlugin()
client = Client(SVC_URL, plugins = [plugin])

online = client.service.Ping()
if not online:
  print 'Service not online. Exiting.'
  raise SystemExit(0)

SVC_USER = os.getenv('ADB_USER')
SVC_PASS = os.getenv('ADB_PASS')

if SVC_USER is None or SVC_PASS is None:
  print "Please set both env vars ADB_USER and ADB_PASS"
  print "with credentials for TaxonAttributeService"
  sys.exit(1)

login = client.service.Login(SVC_USER, SVC_PASS, SVC_USER, 0)

# Set token to use for calls against the service
wci = client.factory.create('ns1:WebClientInformation')
wci['Locale'] = login.Locale
wci['Token'] = login.Token

print "Successfully connected to TaxonAttributeService @ Artdatabanken"
print "Will now fetch redlisted species information, be patient..."
print "This can take a few minutes and there is no way to know progress, currently."

# Define search criteria
wsfsc = client.factory.create('ns1:WebSpeciesFactSearchCriteria')

# We want to combine criteria using AND
op = client.factory.create('ns0:LogicalOperator')
wsfsc['FieldLogicalOperator'] = op.And

# Björn: To get redlist status, we need FactorIds = 743
ids = client.factory.create('ns3:ArrayOfint')
ids.int.append(743)
wsfsc['FactorIds'] = ids

# Björn: To get redlist status, we need IndividualCategoryIds = 0
ids = client.factory.create('ns3:ArrayOfint')
ids.int.append(0)
wsfsc['IndividualCategoryIds'] = ids

# Björn: To get redlist status, we need PeriodIds = 4
ids = client.factory.create('ns3:ArrayOfint')
ids.int.append(4)
wsfsc['PeriodIds'] = ids

# Björn: To get redlist status for specific species
# in this case för Björn (Ursus arctos)
#ids = client.factory.create('ns3:ArrayOfint')
#ids.int.append('100145')
#wsfsc['TaxonIds'] = ids

# Make the service call and retrieve results
try:
  result = client.service.GetSpeciesFactsBySearchCriteria(wci, wsfsc)
except WebFault, e:
  print e
  
# Output results to text file
fo = open(XML_OUT, "wb")
#fo.write(bytes(client.last_received()))
xmldata = xmlpprint(plugin.last_received())
fo.write(bytes(xmldata))
fo.close()

# Clean up / log out and say goodbye
client.service.Logout(wci)

print "Done ... Results are in the file redlistinfo.xml"
print "Please use another tool to convert to .csv ! ;)"

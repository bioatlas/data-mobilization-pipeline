#!/usr/bin/python

import sys
import requests
from requests.exceptions import ConnectionError
import unicodecsv as csv

import config

with open("managed.csv") as f:
    reader = csv.DictReader(f)
    writer = csv.DictWriter(sys.stdout, fieldnames = reader.fieldnames)
    writer.writeheader()
    for row in reader:
        sys.stderr.write(row.get("filename") + "\n")
        if row.get("manage"):
            data = {
                'name': row.get("name"),
                'displayname': row.get("displayName"),
                'description':  row.get("description"),
                'type': row.get("type"),
                'domain': row.get("domain"),
                'source': row.get("source"),
                'environmentalvalueunits': row.get("valueUnits"),
                'classification1': row.get("classification1"),
                'classification2': row.get("classification2"),
                'license_notes': row.get("licenseNotes"),
                'source_link': row.get("sourceLink")
            }
            try:
                r = requests.post(row["manage"], data=data, cookies=config.COOKIES)
            except ConnectionError as err:
                print(err)
        writer.writerow(row)


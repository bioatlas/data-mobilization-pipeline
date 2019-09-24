#!/usr/bin/python

import sys
import requests
from requests.exceptions import ConnectionError
import unicodecsv as csv

import config

with open("managed.csv", "w") as managed:
    with open("layers.csv") as f:
        reader = csv.DictReader(f)
        writer = csv.DictWriter(managed, fieldnames = reader.fieldnames)
        writer.writeheader()
        for row in reader:
            if row.get("filename") and not row.get("manage"):
                files = { "file": open("src/" + row["filename"]) }
                try:
                    r = requests.post(config.URL + "upload", files=files, cookies=config.COOKIES)
                    row["manage"] = r.url
                except ConnectionError as err:
                    print(err)
            writer.writerow(row)


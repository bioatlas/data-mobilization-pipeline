#!/usr/bin/python3
# encoding: utf-8

import sys
import unicodecsv as csv
from taxon_parser import TaxonParser, UnparsableNameException

TYPES = {
    'Art': 'species',
    u'Småarter': 'species',
    'Underart': 'subspecies',
    'Varietet': 'variety',
    'Kollektivtaxon': '',
    'Population': 'population',
}

OCCURRENCE = {
    'Bofast och reproducerande': 'present',
    u'Ej l\xe4ngre bofast, ej tillf\xe4lligt f\xf6rekommande': 'absent',
    u'Ej l\xe4ngre bofast, nu endast tillf\xe4lligt f\xf6rekommande': 'irregular',
    u'M\xf6jligen nationellt utd\xf6d': 'absent',
    u'Regelbunden f\xf6rekomst, ej reproducerande': 'present',
    u'Ej bofast men tillf\xe4lligt reproducerande': 'irregular',
    u'Os\xe4kert om p\xe5tr\xe4ffad': 'doubtful',
    u'Tillf\xe4llig f\xf6rekomst (alt. kvarst\xe5ende)': 'irregular',
    u'P\xe5tr\xe4ffad, ok\xe4nt om reproducerande': 'present',
    u'Ej p\xe5tr\xe4ffad': 'absent',
}

THREATSTATUS = {
    'Kunskapsbrist (DD)': 'DD',
    u'N\xe4ra hotad (NT)': 'NT',
    'Starkt hotad (EN)': 'EN',
    u'S\xe5rbar (VU)': 'VU',
    u'Nationellt utd\xf6d (RE)': 'RE',
    'Akut hotad (CR)': 'CR',
    u'N\xe4ra hotad (NT\xb0)': 'NT',
    u'S\xe5rbar (VU\xb0)': 'VU',
    u'Starkt hotad (EN\xb0)': 'EN',
}

RANKS = {
    'subgenus': 'subgenus',
    'genus': 'genus',
    'class': 'class',
    'order': 'order',
    'phylum': 'phylum',
    'family': 'family',
    'kingdom': 'kingdom',
}

def populatehierarchy(row, taxon):
    while True:
        taxon = taxa[taxon['parentNameUsageID']]
        if taxon['taxonRank'] in RANKS:
            row[RANKS[taxon['taxonRank']]] = taxon['scientificName']
        if not taxon['parentNameUsageID']: break
    return row


# writes the dwc-a taxon core dwc file
core = csv.DictWriter(open('taxon.csv', 'wb'),
        fieldnames=[
            'taxonID', 'scientificName', 'taxonRank',
            'vernacularName', 'scientificNameAuthorship',
            'kingdom', 'phylum', 'class', 'order',
            'family', 'genus', 'subgenus',
            'specificEpithet', 'infraspecificEpithet',
            'taxonomicStatus', 'nomenclaturalStatus', 'taxonRemarks'
        ])

# writer for the distribution extension
distribution = csv.DictWriter(open('distribution.csv', 'wb'),
        fieldnames=[
            'taxonID', 'threatStatus', 'locationID', 'countryCode',
            'occurrenceStatus'
        ])

core.writeheader()
distribution.writeheader()

taxa = {}
dyntaxa = csv.DictReader(open("dyntaxa.csv", 'rb'), delimiter='\t',
        encoding='utf-8-sig')

for row in dyntaxa:
    taxa[row['taxonId']] = row

redlist = csv.DictReader(open('redlist.csv', 'rb'), delimiter=';')
for row in redlist:
    if not row['TaxonId']: continue
    dwc = {}
    dwc['taxonID'] = row['TaxonId']
    dwc['scientificName'] = row['Vetenskapligt namn']
    dwc['vernacularName'] = row['Svenskt namn']
    dwc['taxonRank'] = TYPES[row['Typ']]

    # add taxon info from dyntaxa when available
    taxon = taxa.get(row['TaxonId'])
    if taxon:
        dwc = populatehierarchy(dwc, taxon)
        dwc['scientificNameAuthorship'] = taxon['scientificNameAuthorship']
        dwc['taxonomicStatus'] = taxon['taxonomicStatus']
        dwc['nomenclaturalStatus'] = taxon['nomenclaturalStatus']
        dwc['taxonRemarks'] = taxon['taxonRemarks']

    # populate the specificEpithet and infraspecificEpithet fields
    tp = TaxonParser(dwc['scientificName'])
    try:
        name = tp.parse()
        dwc['specificEpithet'] = name.specificEpithet
        dwc['infraspecificEpithet'] = name.infraspecificEpithet
    except UnparsableNameException as e:
        pass

    ext = {}
    ext['taxonID'] = row['TaxonId']
    ext['locationID'] = 'ISO:SE'
    ext['countryCode'] = 'SE'
    ext['threatStatus'] = THREATSTATUS[row['Kategori']]
    ext['occurrenceStatus'] = OCCURRENCE[row[u'Svensk förekomst']]

    core.writerow(dwc)
    distribution.writerow(ext)


DYNTAXA := "https://api.artdatabanken.se/taxonservice/v1/DarwinCore/DarwinCoreArchiveFile?Subscription-Key=4b068709e7f2427d9fc76bf42d8e2b57"

all: taxon.csv

dyntaxa.csv:
	wget -O dyntaxa.zip $(DYNTAXA)
	unzip -p dyntaxa.zip Taxon.csv > dyntaxa.csv

taxon.csv: dyntaxa.csv
	./prepare-redlist.py

clean:
	rm -f dyntaxa.zip dyntaxa.csv taxon.csv distribution.csv


library(readr)
library(readxl)
library(dplyr)

base <- paste0(
   "https://github.com/bioatlas/data-mobilization-pipeline",
   "/blob/master/molecular-data/"
)

download.file(
  paste0(base, "/taxon.xlsx?raw=true"), 
  destfile = "/tmp/taxon.xlsx")

taxon <- 
  read_xlsx("/tmp/taxon.xlsx", sheet = 1) %>% 
  rename(nameAccordingTo = xxx, taxonRemarks = yyy)
  
download.file(
  paste0(base, "occurrence.xlsx?raw=true"), 
  destfile = "/tmp/occurrence.xlsx")

occ <- 
  read_xlsx("/tmp/occurrence.xlsx", sheet = 1)

ggbn <- 
  read_xlsx("/tmp/occurrence.xlsx", sheet = 2)

emof <- 
  read_xlsx("/tmp/occurrence.xlsx", sheet = 3) %>%
  rename(eventID = EventID)

# TAXON CORE FORMAT

# output a checklist, ie use the "taxon core" format
# with the sequence data in the GGBN extension

taxon_core <- taxon

# we need to resolve taxonConceptIDs to taxonIDs 
# for use in the extension as needs to relate records
# there to the core table using the taxonID

taxon_ext_ggbn <- 
  ggbn %>% 
  left_join(taxon %>% select(taxonID, taxonConceptID), 
    by = c("taxonConceptID" = "taxonConceptID")) %>%
  select(taxonID, everything())

write_tsv(taxon_core, "/tmp/taxon.tsv")
write_tsv(taxon_ext_ggbn, "/tmp/ggbn.tsv")

# OCCURRENCE CORE FORMAT

occ_core <- 
  occ %>%
  mutate(basisOfRecord = "MachineObservation") %>%
  select(occurrenceID, basisOfRecord, everything()) %>%
  # we need to provide a way for the GBIF validator to match names
  # it is not enough with just the taxonConceptID
  mutate(taxonId = "http://www.gbif.org/species/2440940") %>%
  mutate(scientificName = "Alces alces")

# resolve the occurenceID given the EventID, since the
# occurence core format expects to know the relevant
# occurrenceID for every record present in the eMoF extension

lookup <- 
  emof %>% 
  distinct(eventID) %>% 
  left_join(occ, by = c("eventID" = "eventID")) %>% 
  select(occurrenceID, eventID)

# now that we know the occurrence identifiers related
# to each of the distinct events, we can relate the
# emof data back to the occurrence record identifiers

occ_ext_emof <- 
  lookup %>% 
  left_join(emof) %>%
  select(-eventID)


write_tsv(occ_core, "/tmp/occurrence.tsv")
write_tsv(occ_ext_emof, "/tmp/emof.tsv")

pwd <- getwd()

setwd("/tmp")

zip(
    flags = "--junk-paths",
    zipfile = "test.zip", 
    files = c("occurrence.tsv", "emof.tsv", "meta.xml")
)

setwd(pwd)

# upload the test.zip to the validator
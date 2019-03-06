library(readxl)
library(dplyr)
library(stringr)

base <- "~/repos/bioatlas/data-mobilization-pipeline/molecular-data"

maria_xlsx <- file.path(base, "normalised.xlsx")

sheet1 <- read_excel(maria_xlsx, sheet=1) # occurrence
sheet2 <- read_excel(maria_xlsx, sheet=2) # ?
sheet3 <- read_excel(maria_xlsx, sheet=3) # event
sheet4 <- read_excel(maria_xlsx, sheet=4) # measurement or facts
sheet5 <- read_excel(maria_xlsx, sheet=5) # sequences / amplification

bactax <- read_tsv(file.path(base, "bac_taxonomy_r86_clean.tsv"))

occurrence <- 
  sheet1 %>% 
  rename(occurrenceID = ScientificName, 
         scientificName = Species) %>%
  mutate(specificEpithet = word(scientificName, 2)) %>%
 # mutate(scientificName = ifelse(is.na(scientificName), "", scientificName)) %>%
  mutate(specificEpithet = ifelse(is.na(specificEpithet), "", specificEpithet)) %>%
  mutate(scientificName = trimws(paste(Genus, specificEpithet))) %>%
  inner_join(bactax)

occurrence %>% View

event_helper <- 
  sheet2 %>% 
  rename(rowNumber = occurrenceID) %>%
  rename(occurrenceID = scientificName)

# this event_helper can be merged into the occurrence table?
# TODO: figure out what this is....

#event_helper %>% left_join(occurrence)
#occurrence %>% left_join(event_helper)

event <- 
  sheet3 %>% 
  rename(eventID = EventID)

emof <- sheet4

amplification <- 
  sheet5 %>%
  rename(occurrenceID = ScientificName)


browseURL("https://www.gbif.org/dataset/f8ceb4e6-82ff-4325-afc8-eb5e64b5f842")
browseURL("https://www.gbif.org/dataset/3b8c5ed8-b6c2-4264-ac52-a9d772d69e9f")



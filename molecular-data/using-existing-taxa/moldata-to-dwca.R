# Adaptation of dwca_molecular_data_v2.R

# install.packages("readr")
# install.packages("readxl")
# install.packages("dplyr")
library(readr)
library(readxl)
library(dplyr)

base <- paste0(
  "https://github.com/pragermh/data-mobilization-pipeline",
  "/blob/master/molecular-data/using-existing-taxa/indata/"
)

download.file(
  paste0(base, "occur-ggbn-emof-indata.xlsx?raw=true"), 
  destfile = "/tmp/occur-ggbn-emof-indata.xlsx")

download.file(
  paste0(base, "meta.xml"), 
  destfile = "/tmp/meta.xml")

occ <- read_xlsx("/tmp/occur-ggbn-emof-indata.xlsx", sheet = 1)
ggbn <- read_xlsx("/tmp/occur-ggbn-emof-indata.xlsx", sheet = 2)
emof <- read_xlsx("/tmp/occur-ggbn-emof-indata.xlsx", sheet = 3)

lookup <- 
  emof %>% 
  distinct(eventID) %>% 
  left_join(occ, by = c("eventID" = "eventID")) %>% 
  select(occurrenceID, eventID)

occ_ext_emof <- 
  lookup %>% 
  left_join(emof) %>%
  select(-eventID)

setwd("/tmp")

write_tsv(occ, "occurrence.tsv")
write_tsv(ggbn, "ggbn.tsv")
write_tsv(occ_ext_emof, "emof.tsv")

zip(
  flags = "--junk-paths",
  zipfile = "occur-ggbn-emof.zip", 
  files = c("occurrence.tsv", "ggbn.tsv", "emof.tsv", "meta.xml")
)

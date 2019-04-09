# Adaptation of dwca_molecular_data_v2.R

# install.packages("readr")
# install.packages("readxl")
# install.packages("dplyr")
library(readr)
library(readxl)
library(dplyr)

# needs fixing after github push
setwd("xxx")
xldata <- paste0(getwd(),"/indata/occur-ggbn-emof-indata.xlsx")

occ <- read_xlsx(xldata, sheet = 1)
ggbn <- read_xlsx(xldata, sheet = 2)
emof <- read_xlsx(xldata, sheet = 3)

lookup <- 
  emof %>% 
  distinct(eventID) %>% 
  left_join(occ, by = c("eventID" = "eventID")) %>% 
  select(occurrenceID, eventID)

occ_ext_emof <- 
  lookup %>% 
  left_join(emof) %>%
  select(-eventID)

# needs fixing after github push
setwd("xxx")
write_tsv(occ, "occurrence.tsv")
write_tsv(ggbn, "ggbn.tsv")
write_tsv(occ_ext_emof, "emof.tsv")

zip(
  flags = "--junk-paths",
  zipfile = "occur-ggbn-emof.zip", 
  files = c("occurrence.tsv", "ggbn.tsv", "emof.tsv", "meta.xml", "eml.xml")
)

file.remove("occurrence.tsv")
file.remove("ggbn.tsv")
file.remove("emof.tsv")
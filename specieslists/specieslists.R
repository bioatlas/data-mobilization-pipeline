#! /usr/bin/env Rscript

library(readr)
library(taxize)
library(dplyr)

message("Read animalia data and add the taxonID")
animals <- read_csv2("Animalia_fridlysta.csv", 
   locale = locale(encoding = "ISO8859-1"))

ids <- get_gbifid(sciname = animals$scientificName, rows = 1)
taxonID <- attr(ids, "uri")

out <- 
  animals %>% 
  mutate(taxonID = taxonID) %>% 
  select(taxonID, everything())

write_excel_csv(out, "specieslist-animals.csv")


message("Renaming some files")

out <- read_tsv(file = "blacklist.csv")
write_excel_csv(out, "specieslist-black.csv")

out <- read_tsv(file = "graylist.csv")
write_excel_csv(out, "specieslist-gray.csv")

out <- read_csv(file = "flowers.csv")
write_excel_csv(out, "specieslist-flowers.csv")

out <- read_csv(file = "orchids.csv")
write_excel_csv(out, "specieslist-orchids.csv")

out <- read_csv2(
  file = "moss_lav_svamp_fridlysta.csv", 
  locale = locale(encoding = "ISO8859-1")
)

write_excel_csv(out, "specieslist-fungi.csv")


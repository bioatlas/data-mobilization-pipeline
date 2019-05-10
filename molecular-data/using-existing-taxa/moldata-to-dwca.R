# install.packages("readr")
# install.packages("readxl")
# install.packages("dplyr")

library(readr)
library(readxl)
library(dplyr)

base <- paste0(
  "https://github.com/bioatlas/data-mobilization-pipeline",
  "/blob/master/molecular-data/using-existing-taxa/indata/"
)

download.file(
  paste0(base, "occur-ggbn-emof-indata.xlsx?raw=true"), 
  destfile = "/tmp/occur-ggbn-emof-indata.xlsx")

download.file(
  paste0(base, "meta.xml?raw=true"), 
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

# generate dynamic properties with all columns from the 
# extended measurements or facts extension in JSON

library(jsonlite)
library(purrr)

# the unboxing encodes vectors of length 1 as 
# scalars, not arrays in the JSON
toJSON2 <- function(...) toJSON(auto_unbox = TRUE, ...)

# show how to add a column to a tibble then pull it out into a vector
# the parallell map creates a list with named entries for each of the columns across a row
# the regular map then converts these key-value pairs to a (n unboxed) JSON string
dynamicProperties <- 
  ggbn %>% 
  select(-occurrenceID) %>%
  mutate(dynamicProperties = as.character(map(pmap(., list), toJSON2))) %>%
  pull(dynamicProperties)

# add the dynamic properties from the emof ext 
# as a dynamicProperties field in the occurrence core
occ <- 
  occ %>%
  mutate(dynamicProperties = dynamicProperties)

pwd <- getwd()

setwd("/tmp")

write_tsv(occ, "occurrence.tsv", quote_escape = "none")
write_tsv(ggbn, "ggbn.tsv", quote_escape = "none")
write_tsv(occ_ext_emof, "emof.tsv", quote_escape = "none")

zip(
  flags = "--junk-paths",
  zipfile = "occur-ggbn-emof.zip", 
  files = c("occurrence.tsv", "ggbn.tsv", "emof.tsv", "meta.xml")
)


setwd(pwd)

#browseURL("https://www.gbif.org/tools/data-validator/1553852821725")



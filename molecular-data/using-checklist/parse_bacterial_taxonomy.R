library(readr)
library(stringr)

bacterias <- 
  read_tsv("~/repos/bioatlas/data-mobilization-pipeline/molecular-data/bac_taxonomy_r86.tsv", 
    col_names = c("taxonId", "classification"))

x <- bacterias$classification

str_extract_bac <- function(x, letter) 
  str_extract(x, paste0(letter, "__(.*?);")) %>% 
  str_replace(pattern = "\\w__(.*?);", "\\1")

str_extract_species <- function(x, letter) 
  str_extract(x, paste0(letter, "__(.*?)$")) %>% 
  str_replace(pattern = "\\w__(.*?)$", "\\1")

classification <- bind_cols(
  division = str_extract_bac(x, "d"),
  phylum = str_extract_bac(x, "p"),
  class = str_extract_bac(x, "c"),
  order = str_extract_bac(x, "o"),
  family = str_extract_bac(x, "f"),
  genus = str_extract_bac(x, "g"),
  species = str_extract_species(x, "s")
)

bac <- 
  bacterias %>% 
  bind_cols(classification) %>% 
  select(-classification) %>%
  mutate(specificEpithet = word(species, 2)) %>%
  rename(scientificName = species) %>%
  mutate(taxonRank = ifelse(is.na(scientificName), "genus", "species"))

bacterias

write_tsv(bac, "~/repos/bioatlas/data-mobilization-pipeline/molecular-data/bac_taxonomy_r86_clean.tsv")

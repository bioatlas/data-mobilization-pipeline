#! /usr/bin/env Rscript

library(taxize)
library(darwinator)
library(readr)
library(dplyr)

#setwd("~/repos/bioatlas/data-mobilization-pipeline/specieslists/")
url_dyntaxa <- darwinator:::dataset_details(key = "de8934f4-a136-481c-a87a-b0b202b80a31")$endpoints[1,]$url

dl_dyntaxa <-  darwinator:::dwca_download(url_dyntaxa)

df <- read_tsv(unz(dl_dyntaxa, "taxon.txt"))

red <- read_csv("red.csv") 

out <- 
  red %>% 
  select(-row_id) %>% 
  inner_join(df %>% select(dyntaxa_id = id, everything()))

out %>% count(status_abbrev)


lookups <- 
  out %>% 
#  slice(1:2) %>% 
  select(scientificName) %>% 
  .$scientificName

my_gbif_id <- function(x) {
  attr(get_gbifid(x, rows = 1), "uri")  
}

res <- my_gbif_id(lookups)
out$taxonID <- res
out$dyntaxaID <- paste0("https://www.dyntaxa.se/Taxon/Info/", out$dyntaxa_id)

# out %>%
#   slice(1) %>%
#   select(dyntaxaID) %>%
#   .$dyntaxaID %>%
#   browseURL
out <- 
  out %>% 
  select(status = status_eng, threatStatus = status_abbrev, everything(), -c(status_swe, dyntaxa_id, specificEpithet, acceptedNameUsageID)) %>%
  mutate(countryCode = "SE", language = "sv", locationID = "ISO:SE")

write_excel_csv(out, "specieslist-red.csv")

# use same terms as in other specieslists: scientificName, taxonID (from GBIF - the URL), taxonRank
# use speciesDistribution ext (locationID, countryCode, threatStatus ie DD, ER etc)
# use vernacularNames ext (pull data from Dyntaxa)


#! /usr/bin/env Rscript

# read environment vars for GBIF_USER, GBIF_PWD and GBIF_EMAIL values
readRenviron("~/.Renviron")

library(rgbif)
library(jsonlite)
library(readr)
library(dplyr)
library(purrr)

# function to download repatriated data for Sweden (SE)
se_repatriated <- function() {
  
  query <- list(
    creator = unbox(Sys.getenv("GBIF_USER")),
    notification_address = Sys.getenv("GBIF_EMAIL"),
    predicate = list(
      type = unbox("and"),
      predicates = list(
        list(type = unbox("equals"), key = unbox("COUNTRY"),
          value = unbox("SE")),
        list(type = unbox("equals"), key = unbox("REPATRIATED"),
          value = unbox("TRUE"))
      )
    )
  )

  occ_download(body = query, curlopts = list(timeout_ms = 60 * 60 * 1000),
    user = Sys.getenv("GBIF_USER"),
    pwd = Sys.getenv("GBIF_PWD"),
    email = Sys.getenv("GBIF_EMAIL")
  )
}


message("Waiting for dl job to complete.")
key_dl <- se_repatriated()
#key_dl <- "0013936-180824113759888"

message("Current job metadata:")
occ_download_meta(key_dl)

while (occ_download_meta(key_dl)$status != "SUCCEEDED") {   
  Sys.sleep(5)
  cat(".")
}

message("Download job completed. Parsing occurrence.txt data.")

res <- occ_download_get(key_dl)
#res <- "0013936-180824113759888.zip"

spec_dl <- spec_tsv(unz(as.character(res), "occurrence.txt"))
spec_dl$cols$datasetID <- col_character()

df <- 
  read_tsv(file = unz(as.character(res), "occurrence.txt"), col_types = spec_dl, quote = "")

#problems(df) %>% View

message("Parsing done, results:")

message("License type counts: ")
df %>% count(license)

message("Institutions providing the data, top list:")
df %>% count(institutionCode) %>% arrange(desc(n))

message("Top list by dataset name:")
df %>% count(datasetName) %>% arrange(desc(n))
df %>% count(datasetKey) %>% arrange(desc(n))

#library(purrrlyr)
#system.time(
#  df %>% head(10) %>% 
#	by_row(function(x) sum(is.na(x)), .to = "na_count", .collate = "cols") %>% 
#	select(na_count)
#)

message("Removing columns filled entirely with only NAs")

na_counts <- 
  df %>%
  mutate(count_na = apply(., 1,  function(x) sum(is.na(x)))) %>% 
  select(count_na) %>% 
  .$count_na

rows <- which(na_counts == min(na_counts))
long_row <- df %>% slice(rows) %>% head(1)
tr <- t(long_row)
fieldset <- dimnames(tr)[[1]][!is.na(tr)]
res <- df %>% select(one_of(fieldset))

message("Restricting to fields that have non-NA content, ie: ", names(res))
message("Writing output to file se-repat.csv")
write_excel_csv(res, "se-repat.csv")

message("WARN: this is work in progress, this data now needs to be wrangled:\n
TODO: set institutionCode = GBIF
TODO: split into three separate df - by the license_type?
TODO: add meta / XML
TODO: put collectionCode = Repatriated: {license_type}?
TODO: datasetName = value + datasetKey?")


#!/usr/bin/env Rscript

library(readxl)
library(readr)
library(pool)
library(tidyverse)
library(pool)
library(dplyr)
library(rstudioapi)
library(openxlsx)
library(stringi)
library(lubridate)

options(encoding = "utf-8")

setwd("work")

tagged_smtp=read_tsv("tagged_smtp.tsv")

event_core <- 
  tagged_smtp %>%
  # group db data on ...
  distinct(
    StationFieldNumber, ShortName, 
    StartDate, EndDate, Method, 
    LocalityName, Latitude1, Longitude1
  ) %>%
  # map db col names to DwC term names
  select(
    eventID = StationFieldNumber, 
    locationID = ShortName,
    samplingProtocol = Method,
    StartDate, 
    EndDate,
    locality=LocalityName,
    decimalLatitude = Latitude1,
    decimalLongitude = Longitude1
  ) %>%
  # remove rows with empty eventIDs
  filter(!is.na(eventID)) %>%
  # parse and calculate eventDate
  mutate(eventDate = paste0(ymd(StartDate), "/", ymd(EndDate))) %>%
  mutate(eventDate = gsub("NA/NA", NA, eventDate)) %>%
  mutate(eventID = gsub("Event ID ", "", eventID)) %>%
  mutate(geodeticDatum = "WGS84") %>%
  mutate(countryCode = "SE") %>%
  # get col in particular order
  select(
    eventID, eventDate, samplingProtocol, 
    locationID, locality, decimalLatitude, decimalLongitude, 
    geodeticDatum, countryCode)

I_CODE <- "NRM"
C_CODE <- "SMTP_SPP"
#D_ID <- "urn:lsid:bioatlas.se:smtp.insectdiversity:1"
D_ID <- "http://www.gbif.se/ipt/resource?r=smtp-species-lists"
#D_ID <- "https://bioatlas.se/collectory/public/showDataResource/dr41"

LSID_PREFIX <- tolower(paste0(I_CODE, ":", C_CODE, ":"))
HTTPURI_PREFIX <- paste0(D_ID, "/")

occurrence_extension <- 
  tagged_smtp %>%
  # col name mapping to DwC terms
  select(
    occurrenceID = CatalogNumber,
    eventID = StationFieldNumber, 
    scientificName = FullName,
    scientificNameAuthorship = Author,
    taxonRank= Name,
    dateIdentified = DeterminedDate,
    identifiedBy = Determiner,
    preparations = preptype_name,
    # ? = PreparedDate
    # sex = Sex,
    #individualCount = Count,
    individualCount = Total,
    datasetName = analysisGroup
  ) %>%
  distinct() %>%
  mutate(eventID = gsub("Event ID ", "", eventID)) %>%
  mutate(basisOfRecord = "PreservedSpecimen") %>%
  mutate(kingdom = "Animalia") %>%
  mutate(occurrenceStatus = "present") %>%
  mutate(occurrenceID = paste0(LSID_PREFIX, occurrenceID)) %>%
  mutate(recordedBy = "Swedish Malaise Trap Project")

occurrence_extension_gender <- 
  tagged_smtp %>%
  # col name mapping to DwC terms
  select(
    occurrenceID = CatalogNumber,
    eventID = StationFieldNumber, 
    scientificName = FullName,
    scientificNameAuthorship = Author,
    taxonRank= Name,
    dateIdentified = DeterminedDate,
    identifiedBy = Determiner,
    preparations = preptype_name,
    # ? = PreparedDate
     sex = Sex,
    individualCount = Count,
    datasetName = analysisGroup 
  ) %>%
  mutate(eventID = gsub("Event ID ", "", eventID)) %>%
  mutate(basisOfRecord = "PreservedSpecimen") %>%
  mutate(kingdom = "Animalia") %>%
  mutate(occurrenceStatus = "present") %>%
  mutate(occurrenceID = paste0(LSID_PREFIX, occurrenceID))
  # meta <- out_meta_event
  write_smtp_xls <- function(event_core, occurrence_extension, 
    path_out = "smtp_spp.xlsx") {
  wb <- createWorkbook()
  addWorksheet(wb = wb, sheetName = "Sampling Events", gridLines = FALSE)
  writeDataTable(wb = wb, sheet = 1, x = event_core)
  addWorksheet(wb = wb, sheetName = "Associated Occurrences", gridLines = FALSE)
  writeData(wb = wb, sheet = 2, x = occurrence_extension)
  saveWorkbook(wb, path_out,  overwrite = TRUE)  
}

write_dwca <- function(event_core, occurrence_extension, path_out, title) {
  base <- dirname(path_out)
  meta <- read_lines(paste0(base, "/meta-template.xml"))

  # generate event core metadata
  field <- grep("##INDEX_EVENT##", meta, value = TRUE)
  step1 <- stri_replace_all_fixed(field, 
    "##INDEX_EVENT##", 1:length(names(event_core)) - 1)
  step2 <- stri_replace_all_fixed(step1, "##DWCTERM_EVENT##", names(event_core))
  out_meta_event <- stri_replace_first_fixed(meta, field, paste0(collapse = "\n", step2))
  meta <- out_meta_event

  # generate occurrence extension metadata
  field <- grep("##INDEX_OCC##", meta, value = TRUE)
  step1 <- stri_replace_all_fixed(field, 
    "##INDEX_OCC##", 1:length(names(occurrence_extension)) - 1)
  step2 <- stri_replace_all_fixed(step1, "##DWCTERM_OCC##", names(occurrence_extension))
  out_meta_occurrence <- stri_replace_first_fixed(meta, field, paste0(collapse = "\n", step2))
  out_meta <- out_meta_occurrence
  
  # generate eml from template
  eml <- read_lines(paste0(base, "/eml-template.xml"))
  out_eml <- str_replace(eml, "##TITLE##", title)
    
  file_dwca <- paste0("dwca/", path_out)
  temp_dir <- tempdir()
  file_meta <- paste0(temp_dir, "/meta.xml")
  file_data_event <- paste0(temp_dir, "/event.txt")
  file_data_occurrence <- paste0(temp_dir, "/occurrence.txt")
  file_eml <- paste0(temp_dir, "/eml.xml")

  write_lines(out_meta, file_meta)
  write_lines(out_eml, file_eml)
  write_tsv(event_core, file_data_event, na = '')
  write_tsv(occurrence_extension, file_data_occurrence, na = '')

  zip(
    flags = "--junk-paths",
    zipfile = file_dwca, 
    files = c(file_meta, file_data_event, file_data_occurrence, file_eml)
  )
}

# create a dwca with all of the analysis groups
title <- "Swedish Malaise Trap Project (SMTP) Collection Inventory"
write_dwca(event_core, occurrence_extension, "everything.zip", title)

# create a dwca for each analysis group
groups <- split(occurrence_extension, occurrence_extension$datasetName)
for (group in groups) {
  id <- group["datasetName"][1,1]
  title <- paste("Swedish Malaise Trap Project (SMTP) Collection Inventory -", id)
  write_dwca(event_core, group, paste0(id, ".zip"), title)
}


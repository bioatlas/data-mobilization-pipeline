# install.packages("readr")
# install.packages("readxl")
# install.packages("dplyr")

library(readr)
library(readxl)
library(dplyr)

# function to get urls for data files on github
file_url <- function(filename) paste0(
  "https://github.com/bioatlas/data-mobilization-pipeline",
  "/blob/master/molecular-data/using-existing-taxa/indata_its/",
  filename, "?raw=true")

its <- read_csv(file_url("unique_ITS2-ASVs_subset.csv"))


# TODO: perform necessary steps to get the data into
# a format suitable for publication - ie data wrangling etc

# when done with those steps, proceed to generate the dwca-file

# function to generate "meta.xml" needed for the dwca file
# assumes a single occurrence core

write_meta <- function(df, filepath) {

  template <- 
    read_lines(file_url("meta-template.xml"))
  
  zerobased <- 1:length(names(df)) - 1
  
  fields_xml <- paste(collapse = "\n", c(
    sprintf("<id index='%s' />", which(names(df) == "occurrenceID") - 1),
    sprintf("<field index='%s' term='http://rs.tdwg.org/dwc/terms/%s'/>", zerobased, names(df))
    ))
  
  meta <- 
    gsub("<!-- SEARCH_AND_REPLACE_ME -->", fields_xml, template)
  
  write_lines(meta, filepath)
  
}

# output the Darwinc Core Archive file

pwd <- getwd()

setwd("/tmp")

write_tsv(its, "occurrence.tsv", quote_escape = "none")
write_meta(its, "meta.xml")

# TODO: later add EML generation perhaps from template
# for now just use an existing valid static eml.xml file
# download.file(file_url("eml.xml"), "/tmp/eml.xml")

zip(
  flags = "--junk-paths",
  zipfile = "occur-its.zip", 
  files = c("occurrence.tsv", "meta.xml", "eml.xml")
)

setwd(pwd)

#file.copy("/tmp/occur-its.zip", "occur-its.zip", overwrite = TRUE)
#library(finch)
#dwca_validate(file_url("occur-its.zip"), browse = TRUE)


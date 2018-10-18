#!/usr/bin/env Rscript

library(dplyr)
library(xml2)
library(readr)

message("Retrieving redlist data from TaxonAttributeService")
cmd <- "bash -c 'source redlist-rc.sh && python redlist.py'"
system(cmd)

# HACK: This command quickly removes all namespaces
# from the XML file (in order to simplify xml parsing)
message("Processing redlist XML dump (removing namespaces)")
cmd <- "sed -r 's/(a:|s:|i:|xmlns.*?=\".*?\")//g' \\
redlistinfo.xml > rli.xml"
system(cmd)

# HACK: for quick XML parsing using an XML C library fr Python
message("Parsing XML, extracting relevant fields from rli.xml")
message("and converting to rli.csv")
cmd <- "python redlist-xml2csv.py"
system(cmd)

message("Creating lookup table for status_descr")
# src: https://en.wikipedia.org/wiki/Conservation_status
lookup <- read_csv(trim_ws = TRUE, na = character(), file = 
"status_swe, status_abbrev, status_eng
Nationellt utdöd, RE, Extinct
Akut hotad, CR, Critically Endangered
Starkt hotad, EN, Endangered
Sårbar, VU, Vulnerable
Nära hotad, NT, Near Threatened
Livskraftig, LC, Least Concern
Kunskapsbrist, DD, Data Deficient
Ej utvärderad, NE, Not Evaluated
Ej tillämplig, NA, Not Applicable")

message("Processing redlist data into desired output format")
redlist <- read_csv("rli.csv", col_types = "ici")

# Recode some abbreviations 
# TODO: what does these mean?
abbrevs <- c("EN°", "LC°", "NT°", "VU°")
redlist$status_abbrev <- 
  with(redlist, plyr::mapvalues(status_abbrev, 
    from = abbrevs, to = substr(abbrevs, 1, 2)))

# Decorate redlist with info from lookup
res <- 
  redlist %>% 
  left_join(lookup, by = "status_abbrev")

message("Summary of data: ")
res_tally <-
  res %>% 
  group_by(status_abbrev) %>% 
  summarize(n()) %>%
  left_join(lookup, by = "status_abbrev")
print(res_tally)

message("Some dyntaxa ids had missing redlist values: ")
missing_ids <-
  res %>% 
  filter(is.na(status_abbrev)) %>%
  distinct(dyntaxa_id)
message("Count of dyntaxa ids with missing redlist status: ", 
        nrow(missing_ids))

out <- 
  res %>% 
  filter(!is.na(status_abbrev)) %>% 
  filter(!status_abbrev %in% c("LC", "NA", "NE"))

message("Outputting results to file")
write_excel_csv(out, "red.csv")

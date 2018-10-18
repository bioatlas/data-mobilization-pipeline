#! /usr/bin/env Rscript

library(magick)
library(tesseract)
library(stringr)
library(dplyr)
library(readr)

BASE <- "https://www.naturvardsverket.se/upload/var-natur/djur-och-vaxter/fridlyst/"

orchids <- paste0(BASE, "orkideer/artlista-fridlysta-orkideer.pdf")
flowers <- paste0(BASE, "fridlysta-blomvaxter/artlista-fridlysta-blomvaxter.pdf")
lichen <-  paste0(BASE, "fridlysta-blomvaxter/artlista-alla-fridlysta-mossor-lavar-svampar-och-alger.pdf")
animals <- paste0(BASE, "fridlysta-blomvaxter/artlista-alla-fridlysta-djurarter.pdf")

message("lichen and animals lists can not easily be parsed from the PDFs")
message("OCR-ing orchids list ...")

img <- image_read_pdf(orchids)
txt <- image_ocr(img[-c(1)], language = "swe")

orchids_list <- c(
  str_split(txt, "\\n")[[1]][16:40],
  str_split(txt, "\\n")[[2]][4:21]
)

orchids_scinames <- 
  str_extract(orchids_list, "(\\w+\\s+\\w+([—]\\w+)*)$")

orchids_vernaculars <- 
  str_replace_all(orchids_list, orchids_scinames, "") %>%
  str_trim() %>%
  recode(
    "J ohannesnycklar" = "Johannesnycklar",
    "Fj ällyxne" = "Fjällyxne"
  )

library(taxize)

taxonID <- get_gbifid(orchids_scinames, rows = 1)

df_orchids <- tibble(
  taxonID,
  scientificName = orchids_scinames, 
  vernacularName = orchids_vernaculars,
  language = "sv"
  )

df <- df_orchids %>%
  mutate(language = "sv") %>%
  mutate(taxonRank = "species") %>%
  mutate(countryCode = "SE") %>%
  mutate(locationID = "ISO:SE") %>%
  select(taxonID, taxonRank, scientificName, vernacularName, language, countryCode, locationID)


write_excel_csv(df_orchids, "orchids.csv")




message("Getting flowers list ...")

#img <- image_read_pdf(flowers)
#txt <- image_ocr(img[-c(1)], language = "swe")


library(tabulizer)

flowers_tbl <- extract_tables(flowers)
#extract_tables(flowers, output = "data.frame")

library(purrr)

df_flowers <- map_df(flowers_tbl, as_tibble)
df_flowers$V3[158:202] <- ""

res <- df_flowers


joinf <- function(df, range) {
  j <- df %>% slice(range) %>% .$V3 %>% paste0(collapse = " ")
  df[min(range), ]$V3 <- j
  df[setdiff(range, min(range)), ]$V3 <- NA
  df
}

joins <- function(df, range) {
  j <- df_flowers %>% slice(range) %>% .$V2 %>% paste0(collapse = " ")
  df[min(range), ]$V2 <- j
  df[setdiff(range, min(range)), ]$V2 <- NA
  df
}

#df_flowers[77] <- NULL
res <- joinf(res, 17:27)
res <- joinf(res, 78:79)
res <- joinf(res, 83:84)
res <- joinf(res, 103:104)
res <- joinf(res, 105:106)
res <- joinf(res, 107:108)
res <- joinf(res, 119:123)
res <- joinf(res, 207:209)
res <- joinf(res, 221:222)
res <- joinf(res, 234:237)
res <- joinf(res, 238:240)
res <- joinf(res, 280:281)

res <- joins(res, 6:7)
res <- joins(res, 9:11)
res <- joins(res, 29:30)
res <- joins(res, 35:36)
res <- joins(res, 39:40)
res <- joins(res, 41:43)
res <- joins(res, 51:52)
res <- joins(res, 56:58)
res <- joins(res, 65:66)
res <- joins(res, 70:71)
res <- joins(res, 72:73)
res <- joins(res, 78:80)
res <- joins(res, 90:91)
res <- joins(res, 113:114)
res <- joins(res, 134:135)


res$V1[166] <- paste(res$V1[166:167], collapse = " ")
res$V2 <- word(res$V2, start = 1, end = 2)

res[which(res$V1 == "Ishavshästsvans"),]$V3 <- ""

res <- res %>% 
  mutate(keep = !is.na(str_c(V1, V2, V3))) %>%
  filter(keep)

res$V3[c(38, 40:48, 56:59, 61:65, 67:77, 80:84)] <- ""

res$keep[c(129:131, 133:135, 145, 157, 173, 206, 207, 226, 229)] <- FALSE

res <- res %>% 
  filter(keep)

#res %>%
#  filter(grepl("*", V1, fixed = TRUE))

res <- 
  res %>%
  mutate(star_count = str_count(V1, fixed("*"))) %>%
  mutate(vernacularName = str_trim(str_replace_all(V1, fixed("*"), ""))) %>%
  arrange(desc(star_count)) %>%
  select(scientificName = V2, vernacularName, star_count, location = V3)

res <- res %>%
  mutate(scientificName = recode(scientificName, 
       "Familjen Orchidaceae" = "Orchidaceae",
       "hybriden Inula" = "Inula"))

ids <- get_gbifid(res$scientificName, rows = 1)

res$taxonID <- ids

#res %>% slice(which(is.na(ids)))
#as_tibble(ids) %>% filter(match != "found")

#dupes <- res %>%
#  filter(duplicated(V2)) %>% .$V2

#res %>%
#  filter(V2 %in% dupes) %>%
#  View

res <- 
  res %>% 
  mutate(language = "sv") %>%
  mutate(taxonRank = "species") %>%
  mutate(countryCode = "SE") %>%
  mutate(locationID = "ISO:SE") %>%
  select(taxonID, taxonRank, scientificName, vernacularName, language, countryCode, locationID)


write_excel_csv(res, "flowers.csv")

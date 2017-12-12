library(stringi)
library(dplyr)
library(purrr)
library(tidyr)
library(readr)
library(readxl)

# we want to sample synthetic data based on real data
# so we start from real records and inspect those
# we can display one record of real data using

# t(real_data_df %>% head(1)) 
#
# this record looks like below transposed, note that some 
# simple scrambling of data was made, to remove sensitive data
# that could identify specific bears
#
# Position   "A01"              
# Tube       "402580934"       
# RackID     "300042742"       
# Freezer    "MPB-134"         
# NRMID      "NRM-CGI-00260"   
# IndividID  "BI00000"         
# Species    "Ursus arctos"     
# Sex        "Hona"             
# date       "2017-09-11"       
# N_SWEREF99 "7144350"          
# E_SWEREF99 "473722"           
# Municipal  "Strömsund (S)"    
# County     "Jämtlands län (S)"
# MU09 - 1   "104"              
# MU09 - 2   "116"              
# MU10 - 1   "151"              
# MU10 - 2   "151"              
# MU05 - 1   "127"              
# MU05 - 2   "127"              
# MU23 - 1   "173"              
# MU23 - 2   "176"              
# MU51 - 1   "142"              
# MU51 - 2   "150"              
# MU59 - 1   "246"              
# MU59 - 2   "248"              
# G10L - 1   "172"              
# G10L- 2    "182"              
# MU50 - 1   "130"              
# MU50 - 2   "136"  

# the general pattern is evident above and now we want to 
# sample n number of rows of this kind of data
# some variables have fairly understandable names but
# there is a also bunch of more cryptic column names that we need
# with names like "MU51 - 1" etc containing integer values

#* @apiTitle SciBear Data Service
#* @apiDescription Manage Scientific Bear Data using an API

#* @get /scibears
synthetic_sci_bear_data <- function(n = 96) {

  # to understand this upper limit on sample size, 
  # see comments below when generating
  # identifiers with fcn sample(..., replace = FALSE)
  N_MAX <- (1e6 - 1)
  if (n >= N_MAX) stop("too large sample, use lower n")
  if (n < 0) stop("sample size needs to be larger than zero")
  
  # the variables we sample using the sample() fcn
  # we make use of some knowledge we have of the distributions
  Position <- paste0(
    sample(toupper(letters), n, replace = TRUE),
    sprintf("%02i", sample(1:96, n, replace = TRUE))
  )
  
  # here we use info we know about the range
  Tube <- sample(4025809934:4025810029, n, replace = TRUE)
  RackID <- sample(3000142742:3000142742, n, replace = TRUE)
  
  Freezer <- paste0(
    paste0(collapse = "", sample(toupper(letters), 3, replace = TRUE)),
    "-",
    sprintf("%04i", sample(1:9999, n, replace = TRUE))
  )
  
  # for unique ids we use sample() with replace = FALSE and 
  # so we must set an upper limit on n
  
  NRMID <- paste0(
    "NRM-CGI-",
    sprintf("%06i", sample(1:N_MAX, n, replace = FALSE))
  )
  
  IndividID <- paste0(
    "BIO",
    sprintf("%06i", sample(1:N_MAX, n, replace = FALSE))
  )
  
  # we assume they're all bears
  Species <- "Ursus Arctos"
  
  # but the gender is not always known and we may have missing values
  Sex <- sample(c("Hane", "Hona", "Okänd", NA), n, replace = TRUE, 
    prob = c(0.4, 0.4, 0.1, 0.1))
  
  date <- paste0(
    sample(2015:2018, n, replace = TRUE),
    "-",
    sprintf("%02i", sample(1:12, n, replace = TRUE)),
    "-",
    sprintf("%02i", sample(1:28, n, replace = TRUE))
  )
  
  # we know the approx range of coordinates
  N_SWEREF99 <- sample(6838283:7156944, n, replace = TRUE)
  E_SWEREF99 <- sample(400959:677123, n, replace = TRUE)
   
  # we sample some strings for locality data
  Municipal <- sample(c(
    "Strömsund (S)", "Åre (S)", "Sollefteå (S)", 
    "Härjedalen (S)", "Örnsköldsvik (S)", "Krokom (S)"
    ), n, replace = TRUE)
  
  County <- sample(c(
    "Jämtlands län (S)", "Västernorrlands län (S)"
    ), n, replace = TRUE)
  
  # it is now time to assemble the variables into a data frame
  
  df <- tibble(
    Position, Tube, RackID, Freezer, 
    NRMID, IndividID, Species, 
    Sex, date, 
    N_SWEREF99, E_SWEREF99, 
    Municipal, County
  )
  
  # we now deal with the aux cryptic variables with not-so-self-
  # explanatory names - they all contain integer data
  # we can read a schema for those columns inline like this
  aux_schema_txt <- trimws(stri_replace_all_regex(
    pattern = "\\s{2,}", replacement = "\t", 
    str = trimws(read_lines("
      colname   seed
      MU09 - 1   104
      MU09 - 2   116
      MU10 - 1   151
      MU10 - 2   151
      MU05 - 1   127
      MU05 - 2   127
      MU23 - 1   173
      MU23 - 2   176
      MU51 - 1   142
      MU51 - 2   150
      MU59 - 1   246
      MU59 - 2   248
      G10L - 1   172
      G10L- 2    182
      MU50 - 1   130
      MU50 - 2   136
  "))))
    
  aux_schema <- read_tsv(skip = 1,
    file = paste0(aux_schema_txt, "\n", collapse = ""))

  # fcn for synthetic (random) integer metrics for those columns
  random_bear_metric <- function(x, times = n) 
    floor(runif(n, min = .8 * x, max = 1.2 * x))
  
  aux_cols <- 
    aux_schema$seed %>% 
    map(random_bear_metric) %>%
    setNames(aux_schema$colname) %>%
    as_tibble

  res <- bind_cols(df, aux_cols)

  return (res)
  
}

# we can now generate various synthetic datasets
# df <- synthetic_sci_bear_data()
#df <- synthetic_sci_bear_data(n = 1000)
#df <- synthetic_sci_bear_data(n = 1e+6 - 2)

# and output for further processing elsewhere
# write_excel_csv(df, "sci_bear_data.csv")



library(sp)
library(raster)
library(dplyr)
library(readxl)
library(readr)
library(leaflet)
library(tibble)
library(jsonlite)


#* @serializer htmlwidget
#* @get /scibears
scibear_map <- function(n = 96, style = "cluster") {
  # retrieve only the coordinates from the data
  coords <- #read_csv("sci_bear_data.csv") %>% # read_excel("sci_bear.xlsx")
    as_tibble(fromJSON(paste0("http://data.bioatlas.se/scibears?n=", n))) %>%
    select(contains("SWEREF99")) %>%
    select(lon = E_SWEREF99, lat = N_SWEREF99)
  
  # to convert we need to known coordinate reference systems id strings, see
  # http://spatialreference.org/ref/?search=sweref99%20
  SWEREF99TM <- CRS("+init=epsg:3006")
  RT90 <- CRS("+init=epsg:4124")
  
  # NB: the leaflet package wants input in WGS84 and autoconverts to WGS84_PSEUDO 
  WGS84 <- CRS("+init=epsg:4326")  # http://epsg.io/4326 "real" WGS84
  WGS84_PSEUDO <- CRS("+init=epsg:3857")  # http://epsg.io/3857 WGS 84 / Pseudo-Mercator
  
  # we convert coordinates now from SWEREF99TM to WGS84
  p1 <- SpatialPointsDataFrame(coords, data = coords, proj4string = SWEREF99TM)
  p2 <- spTransform(p1, WGS84)
  
  # re-read the initial dataset and add the columns with converted coord data
  df <- #read_csv("sci_bear_data.csv") %>% # read_excel("test.xlsx") %>%
    as_tibble(fromJSON(paste0("http://data.bioatlas.se/scibears?n=", n))) %>%
    mutate(
      lat = p2$lat,
      lon = p2$lon) %>%
    select(lon, lat, everything())
  
  # output the new dataset
  #write_excel_csv(df, "test-extended.csv")
  
  # define map options - first data for the popup display
  pop <-
  	df %>%
  	select(IndividID, Species, Sex, date,
  	  Freezer, RackID, Tube, Position, NRMID,
  	  N_SWEREF99, E_SWEREF99, 
  	  Municipal, County
  	  ) %>%
  	mutate_all(.funs = function(x) recode(as.character(x), .missing = "")) %>%
  	mutate(locality = paste(Municipal, County)) %>%
  	mutate(storage = paste("Freezer:", Freezer, "Rack:", RackID, 
  	  "Tube:", Tube, "Position:", Position, "NRMID:", NRMID)) %>%
  	mutate(specimen = paste(Species, IndividID)) %>%
    select(locality, storage, specimen, Sex, date)
  
  # we want images - some API could be used here 
  # if several species were present
  scibearimg <- paste0(
    "https://upload.wikimedia.org/wikipedia/commons/", 
    "thumb/2/2a/Brown_bear_%28Ursus_arctos_arctos%29_running.jpg/", 
    "1024px-Brown_bear_%28Ursus_arctos_arctos%29_running.jpg"
  )
  
  # assemble the HTML for the popup based on input dataframe
  pop_html <- #htmltools::htmlEscape(
    paste(sep = "", 
      paste0("<img height=100 width=100 src = '", scibearimg, "'/><br/>"),
      "<b>", pop$specimen, "</b><br/>",
      "Sex: ", pop$Sex, "<br/>", 
      "Datum: ", pop$date, "<br/>", 
      pop$locality, "<br/>",
      "Storage: ", pop$storage, ""
    )
  
  # create two different types of maps - clustered and non-clustered
  
  map_circle <-
    leaflet(data = df) %>%
    addProviderTiles("Esri.WorldGrayCanvas", group = "Gray") %>%
  #  addProviderTiles("OpenStreetMap.BlackAndWhite", group = "Gray") %>%
    addMiniMap(position = "bottomright") %>%
    addCircleMarkers(~lon, ~lat, radius = 3, color = "red", 
      popup = pop_html, label = df$IndividID)
  
  map_cluster <- 
    leaflet(data = df) %>%
    addProviderTiles("OpenStreetMap.BlackAndWhite", group = "Gray") %>%
    addMiniMap(position = "bottomright") %>%
    addMarkers(~lon, ~lat, popup = pop_html, label = df$IndividID,
      clusterOptions = markerClusterOptions(), group = "Clustered")
  
  # output the map as a HTML file and open it in the browser
  map <- map_circle # change here to use map_cluster instead?
  if (style == "cluster") map <- map_cluster
  
  return (map)
}

#my_map <- scibear_map()
#htmlwidgets::saveWidget(my_map, file = "sci_bears.html")
#browseURL("sci_bears.html")



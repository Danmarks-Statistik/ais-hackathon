library(feather)
library(purrr)
library(dplyr)
library(sf)
library(ggplot2)
library(tidyr)
library(foreach)

### Skibs data

dat_0 <- read_feather("F:/Hackathon_2018/data/raw/minute_sampled_2017/ais_combined_2017_09.feather") %>% 
  as_tibble()

## Danmarks kort

dk_kort <- read_sf("F:/Hackathon_2018/data/geo/NUTS_RG_01M_2016_4326_LEVL_3.geojson") %>% 
  filter(CNTR_CODE %in% c("DK","SE","NO","DE"))

st_crs(dk_kort)
st_bbox(dk_kort)

plot1 <- ggplot(data = dk_kort) + geom_sf() + xlim(7,16) + ylim(54.5, 58)

plot1

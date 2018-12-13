library(feather)
library(maptools)
library(sp)
library(scales)
library(sf)
library(geojsonio)
library(ggplot2)
library(dplyr)
library(purrr)
library(lubridate)
library(tidyr)
library(plotly)
library(tmap)
library(ggmap)
library(tweenr)
library(rgeos)
library(magick)
library(scales)

Sys.setenv(TZ="UTC")
path <- "F:/Hackathon_2018/data/raw"
fd_sep_2018_ais_5 <- read_feather(sprintf('%s/full_detail_2018_09/ais5/ais5_full_detail.feather',path))
head(fd_sep_2018_ais_5)

fd_sep_2018_aispos <- read_feather(sprintf('%s/full_detail_2018_09/aispos/aispos_full_detail.feather',path))
head(fd_sep_2018_aispos)


fd_2018_min <- list()
for(i in 1:9){
  fd_2018_min[[i]] <- read_feather(sprintf('%s/minute_sampled_2017/ais_combined_2017_0%s.feather',path,i))
  
}

for(i in 10:12){
  fd_2018_min[[i]] <- read_feather(sprintf('%s/minute_sampled_2017/ais_combined_2017_%s.feather',path,i))
  
}


map <- read_sf("F:/Hackathon_2018/data/geo/NUTS_RG_01M_2016_4326_LEVL_3.geojson")

dk_map    <- map %>% filter(CNTR_CODE=="DK")

dk_map$geometry2 <- map(dk_map$geometry, function(x) st_buffer(x,dist=0.05)) 
dk_map$geometry2 <- st_as_sfc(dk_map$geometry2, crs=4326)
dk_map <- st_sf(dk_map, sf_column_name = "geometry2")


p <- ggplot(dk_map %>% select(-geometry2)) + geom_sf()
ggplot(dk_map %>% select(-geometry) %>% rename(geometry=geometry2)) + geom_sf()



# pr. mdr pr. minut


#Laver et label datasæt



#Januar uge 1
Userid_sample <- sample(fd_2018_min[[1]]$Userid,200)

sealfd_2018_min_jan <- fd_2018_min[[1]] %>% filter(Userid %in% c(Userid_sample)) %>% 
st_as_sf( coords=c("Lon","Lat")) %>%  st_set_crs(4326)

sealfd_2018_min_jan_uge_1 <- sealfd_2018_min_jan %>% 
  filter(as.Date(Tid, origin=="1970-01-01 00:00:00", tz="UTC") <=as.Date("2017-01-07 00:00:00", origin="1970-01-01 00:00:00", tz="UTC"))

nest_data <- sealfd_2018_min_jan_uge_1 %>% group_by(day(Tid)) %>% nest()



#Laver forstørrede polygoner for at kunne tælle de skibe der hører til hver havn.

data_jan_uge_1 <- map(nest_data$data, function(x) st_join(x, dk_map %>% select(-geometry)))




sum_fd_2018_by_day    <-  
  map(data_jan_uge_1, 
  function(x) x %>% 
  mutate(dag=day(Tid)) %>% 
  group_by(dag,id, NUTS_NAME) %>% 
  summarise(antal_skibe_landsdel=n_distinct(Userid)) %>% 
  arrange(dag,id))





#Merger antal_skibe_havn på danmarkskortet


sum_fd_2018_by_day[[4]] %>% ungroup() %>%
  mutate(NUTS_NAME=ifelse(NUTS_NAME=="København","Koebenhavn",NUTS_NAME),
         NUTS_NAME=ifelse(NUTS_NAME=="Byen København","Byen Koebenhavn",NUTS_NAME),
         NUTS_NAME=ifelse(NUTS_NAME=="Københavns omegn","Koebenhavns omegn",NUTS_NAME),
         NUTS_NAME=ifelse(NUTS_NAME=="Nordsjælland","Nordsjaelland",NUTS_NAME),
         NUTS_NAME=ifelse(NUTS_NAME=="Vest- og Sydsjælland","Vest- og Sydsjaelland",NUTS_NAME),
         NUTS_NAME=ifelse(NUTS_NAME=="Østjylland","Oestjylland",NUTS_NAME),
         NUTS_NAME=ifelse(is.na(NUTS_NAME),"Skib ikke placeret",NUTS_NAME),) %>% 
  select(-id) %>% st_set_geometry(NULL) %>%  
  htmlTable::htmlTable(rnames=F, header=c("Dag","Landsdel","Antal skibe"))

sum_fd_2018_by_day[[5]] %>% ungroup() %>%
  mutate(NUTS_NAME=ifelse(NUTS_NAME=="København","Koebenhavn",NUTS_NAME),
         NUTS_NAME=ifelse(NUTS_NAME=="Byen København","Byen Koebenhavn",NUTS_NAME),
         NUTS_NAME=ifelse(NUTS_NAME=="Københavns omegn","Koebenhavns omegn",NUTS_NAME),
         NUTS_NAME=ifelse(NUTS_NAME=="Nordsjælland","Nordsjaelland",NUTS_NAME),
         NUTS_NAME=ifelse(NUTS_NAME=="Vest- og Sydsjælland","Vest- og Sydsjaelland",NUTS_NAME),
         NUTS_NAME=ifelse(NUTS_NAME=="Østjylland","Oestjylland",NUTS_NAME),
         NUTS_NAME=ifelse(is.na(NUTS_NAME),"Skib ikke placeret",NUTS_NAME),) %>% 
  select(-id) %>% st_set_geometry(NULL) %>%  
  htmlTable::htmlTable(rnames=F, header=c("Dag","Landsdel","Antal skibe"))


data_til_plots <- sum_fd_2018_by_day %>% 
  map(., function(x) x %>% 
        st_set_geometry(NULL) %>% 
        right_join(dk_map,by="id") %>% 
        st_sf()) 

p <- data_til_plots %>% map(., function(x)
  ggplot(x %>% select(-geometry2) %>% filter(!is.na(id)), aes(fill=-antal_skibe_landsdel)) +
    scale_fill_continuous(labels=c("10","20","30"), breaks=c(-10,-20,-30), limits=c(-40,0)) +
    geom_sf() +
    ggtitle(paste0("dag",x$dag))
  )
plot_data <- map2(sum_fd_2018_by_day,p, function(x,y) 
    y + geom_sf(data=x %>% filter(!is.na(id))))



paths <- lapply(seq_along(plot_data), function(x) paste0("p",x,".png"))

walk2(paths,plot_data,ggsave)



list.files(getwd(),pattern="*.png",full.names = T) %>%
  map(image_read) %>%
  image_join() %>%
  image_animate(fps=0.5) %>%
  image_write("antal_skibe_landsdel_dag.gif")



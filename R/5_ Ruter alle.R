
## Kun unikke punkter

dat_1 <- dat_0 %>%
  distinct() %>% 
  group_by(Userid) %>% 
  arrange(Userid, Tid) %>% 
  filter(!duplicated(Tid)) %>% 
  select(Userid,Stype,Tid,Sog,Thead,Lon,Lat) %>% 
  ungroup()

dat_1

## Opdeling paa

antal_kerner = 15

dat_2 <- dat_1 %>% 
  filter(Userid != 999999999) %>% 
  mutate(ny = !duplicated(Userid), 
         del = ceiling(row_number()/(n()/antal_kerner))) %>% 
  mutate(kerne = cummax(ny*del)) %>% 
  select(-ny,-del) %>% 
  nest(-kerne,.key = "punkter")

dat_2

## Funktion til at identificere start og slut

ture1 <- function(x){
  
  library(dplyr)
  library(tidyr)
  
  x %>% 
    group_by(Userid) %>% 
    arrange(Userid,Tid) %>%
    mutate(foer_1 = lag(Sog,1),
           foer_2 = lag(Sog,2),
           foer_3 = lag(Sog,3),
           foer_4 = lag(Sog,4),
           foer_5 = lag(Sog,5)) %>% 
    arrange(Userid,desc(Tid)) %>%
    mutate(efter_1 = lag(Sog,1),
           efter_2 = lag(Sog,2),
           efter_3 = lag(Sog,3),
           efter_4 = lag(Sog,4),
           efter_5 = lag(Sog,5)) %>% 
    arrange(Userid,Tid) %>% 
    mutate(Start = Sog==0 & foer_1==0 & foer_2==0 & foer_3==0 & foer_4==0 & foer_5==0 & efter_1>0 & efter_2>0 & efter_3>0 & efter_4>0 & efter_5>0,
           Slut = Sog==0 & foer_1>0 & foer_2>0 & foer_3>0 & foer_4>0 & foer_5>0 & efter_1==0 & efter_2==0 & efter_3==0 & efter_4==0 & efter_5==0) %>% 
    ungroup() %>% 
    filter(Start|Slut) %>% 
    select(Userid,Tid,Start,Slut) %>% 
    mutate(Tur = cumsum(Start)) %>% 
    group_by(Userid,Tur) %>% 
    arrange(Userid,Tur,Tid) %>% 
    filter(!duplicated(Slut,fromLast = TRUE)) %>% 
    gather(key = "key", value = "value", Start, Slut) %>% 
    filter(value) %>% 
    select(-value) %>% 
    spread(key = key, value = Tid) %>% 
    filter(!is.na(Slut) & !is.na(Start)) %>% 
    ungroup() %>% 
    mutate(Turid = row_number(),
           Turtid = Slut - Start) %>% 
    select(Turid, Userid, Start, Slut, Turtid)
}

## Funktion til tilkobling af selve ruten

ture2 <- function(x,y){
  
  library(dplyr)
  library(tidyr)
  library(purrr)
  
  x %>% 
    left_join(y %>% select(Userid,Tid,Lon,Lat), by = "Userid") %>% 
    filter(Start <= Tid, Tid <= Slut) %>% 
    select(-Tid) %>% 
    nest(Lon,Lat, .key = "Rute") %>% 
    mutate(Rute_simpel = map(.x = Rute, .f = ~ bind_rows(head(.x,1),tail(.x,1))))
}

## Funktion til omdannelse til SF

ture3 <- function(x){
  
  library(dplyr)
  library(tidyr)
  library(sf)
  
  x %>% 
    gather(key = "Rute_type", value = "Rute", Rute, Rute_simpel) %>% 
    mutate(geometry = map(.x = Rute, .f = ~ .x %>% st_as_sf(coords = c("Lon","Lat")) %>% st_set_crs(4326) %>% st_combine() %>% st_cast("LINESTRING")))
  
}

## Mini test

ttt <- ture1(dat_2$punkter[[1]]) %>% 
  ture2(y = dat_2$punkter[[1]]) %>% 
  ture3()

ttt

### Parallel koersel

dat_2

doParallel::registerDoParallel(cores = antal_kerner)

dat_3 <- foreach(i=1:antal_kerner) %dopar% {
  
  library(dplyr)
  
  ture1(dat_2$punkter[[i]]) %>% 
    ture2(y = dat_2$punkter[[i]]) %>% 
    ture3()
  
}

dat_3[[1]]

## Samler data igen

dat_4 <- bind_rows(dat_3) %>% 
  mutate(geometry = unlist(geometry, recursive = FALSE) %>% st_as_sfc(crs = 4326)) %>% 
  st_sf(sf_column_name = "geometry")

dat_4

save(dat_4, file = "Alleture.RData")

## Mega plot

unique(dat_4$Rute_type)

filter(dat_4,Rute_type=="Simpel")

ggplot() +
  geom_sf(data = filter(dat_4,Rute_type=="Rute_simpel"))

plot1 +
  geom_sf(data = filter(dat_4,Rute_type=="Rute_simpel"))

plot1 +
  geom_sf(data = filter(dat_4,Rute_type=="Rute"))

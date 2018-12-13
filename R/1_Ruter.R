library(ggplot2)

## Udvælg godt skib

skib_0 <- dat_0 %>% 
  group_by(Userid) %>% 
  summarise(Antal = n(),
            Lon_min = min(Lon),
            Lon_max = max(Lon),
            Lat_min = min(Lat),
            Lat_max = max(Lat),
            Sog_max = max(Sog)) %>% 
  arrange(-Antal)

skib_0

## Ruter  filter(Userid==219570000) %>% 

219011021

dat_1 <- dat_0 %>% 
  filter(Userid %in% skib_0$Userid[1:100]) %>% 
  group_by(Userid) %>% 
  arrange(Userid,Tid) %>% 
  mutate(Lon_1 = lag(Lon),
         Lat_1 = lag(Lat)) %>% 
  filter(Lon != Lon_1 | Lat != Lat_1 | is.na(Lon_1) | is.na(Lat_1)) %>% 
  mutate(Lon_1 = lag(Lon),
         Lat_1 = lag(Lat)) %>% 
  filter(abs(Lon - Lon_1)>0.001 | abs(Lat - Lat_1)>0.001 | is.na(Lon_1) | is.na(Lat_1)) %>% 
  mutate(Tid_num = as.numeric(Tid, origin = "1970-01-01 00:00:00"),
         Tid_num_min = min(Tid_num),
         Tid_diff = (Tid_num - Tid_num_min)/(60*60),
         Antal = n())

dat_1

## Tegne

plot1 +
  geom_path(data = dat_1, mapping = aes(x = Lon, y = Lat, colour = Tid_diff, group = Userid)) +
  scale_colour_gradient(low = "red", high = "green")

plot1 +
  geom_path(data = dat_1, mapping = aes(x = Lon, y = Lat, colour = Antal, group = Userid)) +
  scale_colour_gradient(low = "red", high = "green")

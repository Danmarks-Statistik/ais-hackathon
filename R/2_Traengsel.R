library(ggplot2)

## Optælling i kvadrater

dig = 2

dat_1 <- dat_0 %>% 
  transmute(Lon = round(Lon,digits = dig),
            Lat = round(Lat,digits = dig))

dat_1
summary(dat_1)

dat_2 <- dat_1 %>% 
  group_by(Lon,Lat) %>% 
  summarise(Antal = n()) %>% 
  mutate(log_Antal = log(Antal)) %>% 
  ungroup() %>% 
  mutate(ID = row_number())

dat_2

dat_3 <- bind_rows(dat_2 %>% mutate(id2 = 1),
                   dat_2 %>% mutate(Lat = Lat + 10^(-dig), id2 = 2),
                   dat_2 %>% mutate(Lat = Lat + 10^(-dig), Lon = Lon + 10^(-dig), id2 = 3),
                   dat_2 %>% mutate(Lon = Lon + 10^(-dig), id2 = 4)) %>% 
  arrange(ID, id2)

dat_3

## Plot

ggplot() +
  geom_polygon(data = dat_3, mapping = aes(x = Lon, y = Lat, fill = log_Antal, group = ID)) +
  geom_sf(data = dk_kort) + xlim(7,16) + ylim(54.5, 58) +
  theme_minimal()

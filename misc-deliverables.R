install.packages("mapproj")
install.packages("ggrepel")

library(ggplot2)
library(ggmap)
library(maps)
library(mapdata)
library(mapproj)
library(ggrepel)

#create top20 table with total points & latlong
dt_top20 <- dt_ranking[order(-total_points),head(.SD,20)]
dt_top20 <- dt_top20[,.(state_id, city_ascii, county_fips, total_points)]
dt_latlng <- selected_cities[,.(county_fips, lat, lng)]
dt_top20 <- merge(dt_top20, dt_latlng, by="county_fips")

#misc
rownames(dt_top20) <- dt_top20$city_ascii

#map
states <- map_data("state")

#draw base
gg1 <- ggplot(data=dt_top20, aes(x = lng, y = lat, label = rownames(dt_top20))) + 
  geom_polygon(data = states, aes(x = long, y = lat, group = group), fill = "grey", color = "white", inherit.aes = FALSE) +
  coord_fixed(1.3) +
  coord_map("albers",lat0=39, lat1=45) +
  labs(x = NULL, y = NULL, title = "Top 20 'happiest' cities.") +
  geom_point(aes(size = total_points, fill = total_points), shape=21, alpha=0.8) +
  scale_size_continuous(range=c(2,6)) +
  geom_text_repel() +
  guides(fill = FALSE)

#export full ranking table
write.csv(dt_ranking[order(-total_points)], file = "ranking_full.csv")
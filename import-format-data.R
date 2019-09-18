install.packages("data.table")
library(data.table)


#import city dataset to data table
dt_cities <- setDT(read.csv(file="data/uscitiesv1.5.csv", header=TRUE, sep=","))

#select our cities of interest, top 3 population for each state
selected_cities <- dt_cities[order(-population),head(.SD,3),by=state_id]
selected_cities <- selected_cities[,.(state_id, city_ascii, county_name, county_fips, lat, lng, population, density, zips)]


#import libraries dataset
libraries <- read.csv(file="data/libraries/PLS_FY2016_AE_pupld16a.csv", header=TRUE, sep=",")

#library count
lib_zip_count <- data.frame(table(libraries$ZIP))
lib_zip_count$Freq[match(unlist(selected_cities$zips), lib_zip_count$Var1)]

getFreq <- function(x) lib_zip_count$Freq[match(x, lib_zip_count$Var1, nomatch = 0)]
funSplit <- function(x) strsplit(as.character(x), " ")
rmLead0 <- function(x) sub("^0+", "", x)

#convert cities zips field to vector, remove leading zeros
selected_cities$zips <- sapply(selected_cities2$zips, funSplit)
selected_cities$zips <- sapply(selected_cities2$zips, rmLead0)

selected_cities$lib_count <- sapply(selected_cities$zips[], getFreq)
selected_cities$lib_count <- sapply(selected_cities$lib_count[], sum)


#read tax info from webpage, parse table
taxpage = readLines('https://wallethub.com/edu/best-worst-states-to-be-a-taxpayer/2416/')
mypattern = '<td>([^<]*)</td>'
datalines = grep(mypattern,taxpage[379:864],value=TRUE)
getexpr = function(s,g)substring(s,g,g+attr(g,'match.length')-1)
gg = gregexpr(mypattern,datalines)
matches = mapply(getexpr,datalines,gg)
result = gsub(mypattern,'\\1',matches)
names(result) = NULL

#format tax dataframe
dt_tax = as.data.table(matrix(result,ncol=7,byrow=TRUE))
names(dt_tax) = c('tax_rank','state_id','state_local_tax','on_us_med_house','diff','on_state_med_house','col_adj_tax_rank')

#use state.abb to map to cities
dt_tax$state_id <- state.abb[match(dt_tax$state_id,state.name)]
dt_tax[11,"state_id"] <- "DC"

#add to main table
selected_cities <- merge(selected_cities, dt_tax[,.(state_id,state_local_tax,col_adj_tax_rank)], by="state_id")


#import & format econ dataset
dt_econ <- setDT(read.csv(file="data/econ/ACS_17_5YR_DP03_with_ann.csv", header=TRUE, sep=","))
dt_econ <- dt_econ[,.(GEO.id2,HC03_VC07,HC01_VC36,HC01_VC114,HC03_VC131,HC03_VC161)]
names(dt_econ) <- c("county_fips","unemp_pct","mean_commute","med_fam_inc","hlth_insured_pct","fam_pov_pct")

#add to main table
selected_cities <- merge(selected_cities, dt_econ, by="county_fips")


#import & format housing dataset
dt_housing <- setDT(read.csv(file="data/housing/ACS_17_5YR_DP04_with_ann.csv", header=TRUE, sep=","))
dt_housing <- dt_housing[,.(GEO.id2,HC01_VC146,HC01_VC191)]
names(dt_housing) <- c("county_fips","med_mortgage","med_rent")

#add to main table
selected_cities <- merge(selected_cities, dt_housing, by="county_fips")


#import & format crime dataset
dt_crime <- setDT(read.csv(file="data/crime/10tbl08.csv", header=TRUE, sep=","))
dt_crime <- dt_crime[,.(gsub("\\d", "", ï..State), gsub("\\d", "", City), Violent.crime, Property.crime)]
names(dt_crime) <- c("state_id","city_ascii","violent_crime","property_crime")

dt_crime$state_id <- state.abb[match(dt_crime$state_id,toupper(state.name))]
dt_crime[1174,"state_id"] <- "DC"

#add to main table
selected_cities <- merge(selected_cities, dt_crime, by = c("state_id", "city_ascii"), all.x = TRUE)


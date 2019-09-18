install.packages("data.table")
library(data.table)

dt_ranking <- selected_cities[,.(state_id, city_ascii, county_fips)]


#points calculations
dt_ranking$commute <- 3 - (round(3 * rank(selected_cities$mean_commute)/length(selected_cities$mean_commute), digits=1))
dt_ranking$income <- round(9 * rank(selected_cities$med_fam_inc)/length(selected_cities$med_fam_inc), digits=1)
dt_ranking$healthcare <- round(6 * rank(selected_cities$hlth_insured_pct)/length(selected_cities$hlth_insured_pct), digits=1)
dt_ranking$unemployment <- 6 - (round(6 * rank(selected_cities$unemp_pct)/length(selected_cities$unemp_pct), digits=1))

#convert columns to numeric vectors so we can work with them
selected_cities$med_mortgage <- as.numeric(as.character(selected_cities$med_mortgage))
selected_cities$med_fam_inc <- as.numeric(as.character(selected_cities$med_fam_inc))
selected_cities$med_rent <- as.numeric(as.character(selected_cities$med_rent))
selected_cities$violent_crime <- as.numeric(gsub(",","",selected_cities$violent_crime))
selected_cities$property_crime <- as.numeric(gsub(",","",selected_cities$property_crime))

#divide annual income by mortgage/rent for an income to housing cost ratio
dt_ranking$mortgage <- round(3 * rank(selected_cities$med_fam_inc / selected_cities$med_mortgage)/length(selected_cities$med_fam_inc), digits=1)
dt_ranking$rent <- round(3 * rank(selected_cities$med_fam_inc / selected_cities$med_rent)/length(selected_cities$med_fam_inc), digits=1)

#function to handle NA values in calculation
prank<-function(x) ifelse(is.na(x),NA,rank(x)/sum(!is.na(x)))

#libraries and crimes per capita
dt_ranking$libraries <- round(3 * rank(selected_cities$lib_count / selected_cities$population)/length(selected_cities$population), digits=1)
dt_ranking$violent_crime <- round(3 * prank(selected_cities$population / selected_cities$violent_crime), digits=1)
dt_ranking$property_crime <- round(3 * prank(selected_cities$population / selected_cities$property_crime), digits=1)

#tax rate strip % char
selected_cities$state_local_tax <- as.numeric(gsub("%","",selected_cities$state_local_tax))
dt_ranking$taxes <- 3 - (round(3 * rank(selected_cities$state_local_tax)/length(selected_cities$state_local_tax), digits=1))

#population
dt_ranking$population <- round(9 * prank(selected_cities$population), digits=1)

#sum points for our total score
dt_ranking <- dt_ranking[, total_points := rowSums(.SD, na.rm = TRUE), .SDcols = 4:14][]

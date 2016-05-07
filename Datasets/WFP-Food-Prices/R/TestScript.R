#Location of file should be in 
#FoodPricesFileLocation
#e.g. 
#FoodPricesFileLocation <- "C:\\RandomDirectory\\WFP data\\WFPVAM_FoodPrices.csv"
#Location of file is mentioned at https://github.com/datamission/WFP/wiki/Datasets-wiki-page#food-prices
stopifnot("FoodPricesFileLocation" %in% ls())

#Read the CSV
TheFoodPrices <- read.csv(file = FoodPricesFileLocation, header=TRUE,stringsAsFactors = FALSE) 
str(TheFoodPrices)

#For which countries do we have data?
table(TheFoodPrices$adm0_name)

#convert mp_year and mp_month to a date
#create first a date as a character in YYYY-MM-DD format
TheFoodPrices$TheDateAsCharacter <- with(TheFoodPrices, paste0("01-",formatC(mp_month,format = "d",width =2, flag = "0"),"-",as.character(mp_year)))
TheFoodPrices$TheDate <- with(TheFoodPrices,TheFoodPrices$TheDateAsCharacter)

#load dplyr package
library(dplyr)

#min & max date per country)
TheFoodPrices %>% group_by(adm0_name) %>% summarise(FirstDate = min(TheDate),LastDate=max(TheDate))

#Note that for some markets there are multiple, see MP_CommoditySource

#find those combinations of adm0_name, adm1_name,mkt_name,cm_name and TheDate for which there are multiple mp_commoditysource
TheFoodPrices %>% group_by(adm0_name,adm1_name,mkt_name,cm_name,TheDate) %>% summarise(NrOfSources = length(unique(mp_commoditysource))) %>% filter(NrOfSources > 1)
#Location of file should be in 
#FoodConsumptionScoresFileLocation 
#e.g. 
#FoodConsumptionScoresFileLocation <- "C:\\RandomDirectory\\WFP data\\dbo-foodconsumptionscores.csv"
#Location of file is mentioned at https://github.com/datamission/WFP/wiki/Datasets-wiki-page#food-consumption-score 
stopifnot("FoodConsumptionScoresFileLocation" %in% ls())

#Read the CSV
TheFCS_VAM <- read.csv(file = FoodConsumptionScoresFileLocation, header=TRUE,stringsAsFactors = FALSE) 
str(TheFCS_VAM)

#For which countries do we have data?
table(TheFCS_VAM$ADM0_NAME)

#convert FCS_Year and FCS_Month to a date
#create first a date as a character in YYYY-MM-DD format
TheFCS_VAM$TheDateAsCharacter <- with(TheFCS_VAM, paste0(as.character(FCS_Year),"-",formatC(FCS_Month,format = "d",width =2, flag = "0"),"-01"))
TheFCS_VAM$TheDate <- with(TheFCS_VAM,as.Date(TheDateAsCharacter))

#load dplyr package
library(dplyr)

#Note that FCS_poor, FCS_Borderline & FCS_Acceptable always add to 100 (i.e. it's a percentage)
with(TheFCS_VAM, summary(FCS_poor+ FCS_Borderline + FCS_Acceptable))

#For most countries only one month, but for some 10 - 13 months of data
TheFCS_VAM %>% group_by(ADM0_NAME) %>% summarise(FirstDate = min(TheDate),LastDate=max(TheDate),Number_Date = length(unique(TheDate)))

#sometimes multiple DataSources per country
TheFCS_VAM %>% group_by(ADM0_NAME) %>% summarise(Number_Date = length(unique(TheDate)), Number_Target_Group = length(unique(Target_Group)),
	Number_Methodology = length(unique(Methodology)),
	Number_FCS_DataSource = length(unique(FCS_DataSource)),
	Number_Indicator_Type = length(unique(Indicator_Type)))

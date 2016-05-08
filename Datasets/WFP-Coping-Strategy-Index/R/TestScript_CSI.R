#Location of file should be in 
#CopingStrategyIndicesFileLocation 
#e.g. 
#CopingStrategyIndicesFileLocation <- "C:\\RandomDirectory\\WFP data\\dbo-copingstrategiesindexes.csv"
#Location of file is mentioned at https://github.com/datamission/WFP/wiki/Datasets-wiki-page#coping-strategy-index
stopifnot("CopingStrategyIndicesFileLocation" %in% ls())

#Read the CSV
TheCSI_VAM <- read.csv(file = CopingStrategyIndicesFileLocation, header=TRUE,stringsAsFactors = FALSE) 
str(TheCSI_VAM)

#For which countries do we have data?
table(TheCSI_VAM$ADM0_NAME)

#convert CSI_Year and CSI_Month to a date
#create first a date as a character in YYYY-MM-DD format
TheCSI_VAM$TheDateAsCharacter <- with(TheCSI_VAM, paste0(as.character(CSI_rYear),"-",formatC(CSI_rMonth,format = "d",width =2, flag = "0"),"-01"))
TheCSI_VAM$TheDate <- with(TheCSI_VAM,as.Date(TheDateAsCharacter))

#load dplyr package
library(dplyr)

#Note that CSI_rNoCoping, CSI_rLowCoping, CSI_rMediumCoping, CSI_rHighCoping  always add to 100 (i.e. it's a percentage)
with(TheCSI_VAM, summary(CSI_rNoCoping+CSI_rLowCoping+ CSI_rMediumCoping+ CSI_rHighCoping))

#For most countries only one month, but for some 12 months of data
TheCSI_VAM %>% group_by(ADM0_NAME) %>% summarise(FirstDate = min(TheDate),LastDate=max(TheDate),Number_Date = length(unique(TheDate)))

#Note that the thresholds between the 3 categories are not always the same
length(unique(TheCSI_VAM$CSI_rLowMediumThreshold))
length(unique(TheCSI_VAM$CSI_rMediumHighThreshold))

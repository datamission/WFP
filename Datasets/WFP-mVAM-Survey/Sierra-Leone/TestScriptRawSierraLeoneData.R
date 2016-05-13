#Location of file should be in 
#SLRawmVAMFileLocation
#e.g. 
#SLRawmVAMFileLocation <- "C:\\RandomDirectory\\WFP data\\data_SL_hackathon_clean.csv"
#File is on USB stick in USB\Sierra Leone\mVAM\Data\
stopifnot("SLRawmVAMFileLocation" %in% ls())

TheData <- read.csv(file = SLRawmVAMFileLocation, stringsAsFactors = FALSE)

table(TheData$SvyDate)

TheData$SvyDateAsDate <- as.Date(TheData$SvyDate,format = "%m/%d/%Y")
TheData$ObsDateAsDate <- as.Date(TheData$ObsDate,format = "%m/%d/%Y")


length(unique(TheData$RspID))
length(TheData$RspID)
table(table(TheData$RspID))

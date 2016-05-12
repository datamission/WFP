TheData <- read.csv(file = YemenRawmVAMFileLocation, stringsAsFactors = FALSE)
table(TheData$num_phones)
table(TheData$num_phones,useNA = "always")

 table(TheData$OperatorID_code )

length(TheData$RspID)
length(unique(TheData$RspID))
 table(table(TheData$RspID))

 sum(table(table(TheData$RspID)))
 
subset(TheData,RspID=="CTC270815A37")
#HouseType changes once
subset(TheData,RspID=="CTC270815A37")$HouseType
subset(TheData,RspID=="CTC270815A37")$FCS
subset(TheData,RspID=="CTC270815A37")$rCSI

#Still need to change SvyDate & ObsDate to a Date which can be interpreted by R.
TheData$SvyDateAsDate <- as.Date(TheData$SvyDate,format = "%d%b%Y")
TheData$ObsDateAsDate <- as.Date(TheData$ObsDate,format = "%d%b%Y")
#check it works
TheData[sample(1:20000,20),c("SvyDateAsDate","SvyDate")]
TheData[sample(1:20000,20),c("ObsDateAsDate","ObsDate")]


#What can we do? Sankey graphs? Cohort Analysis?
#http://stackoverflow.com/questions/34571899/sankey-diagram-in-r
#Hidden Markov model (moving from one state to the other), see e.g HiddenMarkov or DOBAD package
#Or use TraMineR package

#Be very careful that you only see those respondents who have filled in the survey

#Note that households can be rather big in the Middle east, so num_phones is indeed number of phones (and can be big)
summary(TheData$num_phones)

#split the respondents in group (for testing & training)
AllTheRespondents <- unique(TheData$RspID)
set.seed(20160514)
JustFewRespondents <- sample(AllTheRespondents,round(length(AllTheRespondents)*0.25),replace=FALSE)

SubsetTheData <- subset(TheData,RspID %in% JustFewRespondents)
dim(TheData)
dim(SubsetTheData)


 table(table(SubsetTheData$RspID))
 
 #Want info per respondent
 #e.g. Number of times in dataset
 #Month of first contact
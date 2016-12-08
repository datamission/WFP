#Note that I haven't used an interactive ipython like environment because this
#program uses data that is not publicly available

###########################################################################################################################
#
# Using the following libraries
#
###########################################################################################################################

library(ggplot2)
library(dplyr)
library(reshape2)
library(alluvial)

###########################################################################################################################
#
# Reading file and putting some columns in right format
# One has to set the value SLRawmVAMFileLocation to the location of the file with Sierra Leone mVAM data.
# This script assumes this file is the one given at the DataMission hackathon, i.e. one with 14696 lines and 29 columns
# With data from February 2016 and from November 2014 up to and including the December 2015.
#
###########################################################################################################################

#Change the next line for the correct location of the CSV.
SLRawmVAMFileLocation <- "C:\\RandomDirectory\\WFP data\\data_SL_hackathon_clean.csv"
#Location of file should be in 
#SLRawmVAMFileLocation
#e.g. 
#SLRawmVAMFileLocation <- "C:\\RandomDirectory\\WFP data\\data_SL_hackathon_clean.csv"
#File was on USB stick in USB\Sierra Leone\mVAM\Data\

stopifnot("SLRawmVAMFileLocation" %in% ls())

TheData <- read.csv(file = SLRawmVAMFileLocation, stringsAsFactors = FALSE)

table(TheData$SvyDate)

TheData$SvyDateAsDate <- as.Date(TheData$SvyDate,format = "%m/%d/%Y")
TheData$ObsDateAsDate <- as.Date(TheData$ObsDate,format = "%m/%d/%Y")


length(unique(TheData$RspID))
length(TheData$RspID)
table(table(TheData$RspID))

###########################################################################################################################
#
# Split the respondents in two groups (Train & Test). Do this per respondent to ensure that all surveys 
# of one respondent are in Train or in Test group, but not in both.
# So the data frame SubsetTheData contains the Train set. While TheData_TestSet is is the Test set.
#
# Note that so far this script only uses the Train set. Haven't tested predictions found from Train set
# on Test set. Yet.
#
###########################################################################################################################


AllTheRespondents <- unique(TheData$RspID)
set.seed(20160514)
JustFewRespondents <- sample(AllTheRespondents,round(length(AllTheRespondents)*0.25),replace=FALSE)

SubsetTheData <- subset(TheData,RspID %in% JustFewRespondents)
TheData_TestSet <- subset(TheData,!(RspID %in% JustFewRespondents))
dim(TheData)
dim(SubsetTheData)

table(table(SubsetTheData$RspID))
 
tail(sort(table(SubsetTheData$RspID)))

###########################################################################################################################
#
# Not all columns are available for all months
# 
###########################################################################################################################

#No SvyDateAsDate in 2015-01 and 2015-02, see
with(SubsetTheData,table(SvyDateAsDate,is.na(ObsDateAsDate)))

with(SubsetTheData,table(SvyDateAsDate,is.na(Sentiment)))

#RspTime since 2015-07. RspTime = Total response time of respondent to complete survey
with(SubsetTheData,table(SvyDateAsDate,is.na(RspTime)))

#ToiletType since 2015-01-01
with(SubsetTheData,table(SvyDateAsDate,ToiletType==""))

###########################################################################################################################
#
# For the analysis I want to have the data in two different Data Frames:
# 1) This is a dataframe with one row for each combination of month & respondent.
#    Even if a respondent did not participate in a particular month this data frame will have a row for that
#    month/participant but then with Participated = FALSE
#    This data frame is created by running ReturnInfoOnRespondentAndMonth for each respondent.
#    Output for the subset is SubsetWithMoreInfoPerRspAndMonth. 
#
# 2) This is a dataframe with general info on each respondent. Mostly info that is known about the respondent the first
#    time he/she takes part in the survey. So most of the info in the dataframe does not require "forward snooping"
#    If it's info that can change during the dataset, then I have both a _First column (the first value encountered)
#    and _Changed (a boolean that indicates whether that value has changed (and yes, that's a bit of snooping))
#    This dataframe is created by running ReturnInfoOnRespondent for each respondent.
#    Output for the subset is named SubsetWithMoreInfoPerRsp.
#
# For both dataframes I don't use the data from "2016-02-01" because there is no data at all from 2016-01-01. 
# This because I'm interested in predicting whether someone will participate next month. It's hard to handle a
# one month gap in the data in a "nice" way.
# 
###########################################################################################################################

AllTheValidSvyDate <- sort(unique(SubsetTheData$SvyDateAsDate))
#I want to remove "2016-02-01" because no data at all from 2016-01-01
AllTheValidSvyDate <- AllTheValidSvyDate[AllTheValidSvyDate!=as.Date("2016-02-01")]


#For general info about ReturnInfoOnRespondentAndMonth, see above.
#Info on the input parameters:
#   InputDF:
#       data frame, containing info on one respondent only. 
#   ValidSvyDate:
#       vector of one or more Dates.
#       Only data from InputDF is used where SvyDateAsDate is in ValidSvyDate. 
#   IncludeStatusNextMonth:
#       Boolean. If TRUE then include StatusNextMonth in the output dataframe.
#   MinrCSIHungry:
#       Integer. Someone is classified as being Hungry on a certain month if his/her rCSI on a month is higher than (or equal to) MinrCSIHungry
#   IncludeInfoOnNrMonthsHungry:
#       Boolean. If TRUE, then include MonthBeforeAfterFirstHunger in output data frame
#
#Output is InputDF, with some extra columns added. Those columns are:
#   Participated:
#       Boolean. Did the respondent participate in the survey on this month?
#   NrMonthParticipated:
#       Integer. How many months has the respondent participated up to and including this month? Note that NrMonthParticipated does not
#       take ValidSvyDate into account.
#   Status:
#       String. Either "Participant", "Has not participated yet" or "Does not participate" .
#   MonthBeforeAfterFirstHunger:
#       Integer. Used to know what happens to a respondent after the first time he/she was hungry. So if someone was hungry
#       then MonthBeforeAfterFirstHunger == 0 on the first month he/she was hungry, with negative numbers before that month, and positive
#       numbers after that month.
#       MonthBeforeAfterFirstHunger is NA if someone wasn't hungry at all during the survey, or if he/she was already hungry on the first
#       survey (because then it's not known whether the respondent was already hungry before the first month of the survey).
#   StatusNextMonth:
#       String. The status of the respondent on the next month. For the last month it's "Not known".
#       Can be used to train models to predict if someone will participate next month.
ReturnInfoOnRespondentAndMonth <- function(InputDF,ValidSvyDate,IncludeStatusNextMonth,MinrCSIHungry=25,IncludeInfoOnNrMonthsHungry=TRUE){
	#Order input based on SvyDateAsString
	stopifnot(c("RspID","SvyDateAsDate","rCSI") %in% colnames(InputDF))
	stopifnot(length(unique(InputDF$SvyDateAsDate))== length(InputDF$SvyDateAsDate))
	TempDF <- InputDF[order(InputDF$SvyDateAsDate), ]
	
	TheRspId <- unique(InputDF$RspID)
	stopifnot(length(TheRspId) ==1)
	
	TempDF$NrMonthParticipated <- seq_along(TempDF$SvyDateAsDate)
	TempDF$Participated <- TRUE
	TempDF$Hungry <- (TempDF$rCSI >= MinrCSIHungry)

	#Merge with ValidSvyDate
	TempDFToMergeWith <- data.frame(SvyDateAsDate = ValidSvyDate)
	MergedDF <- merge(TempDF, TempDFToMergeWith, all.y = TRUE) #Note the all.y because I don't want those who are in InputDF but not in TempDFToMergeWith
	MergedDF <- MergedDF[order(MergedDF$SvyDateAsDate), ]
	
	#Compute extra columns
	MergedDF$Participated[is.na(MergedDF$Participated)] <- FALSE #After the merge() those rows which weren't in original TempDF have NA as Participated
	MergedDF$NrMonthParticipated[is.na(MergedDF$NrMonthParticipated)] <- 0
	MergedDF$NrMonthParticipated <- cummax(MergedDF$NrMonthParticipated)
	MergedDF$RspID <- TheRspId #To ensure that all lines have the RspID, not just those of the months when participant participated
	MergedDF$Status <- "Participant"
	MergedDF$Status[MergedDF$NrMonthParticipated==0] <- "Has not participated yet"
	MergedDF$Status[(MergedDF$NrMonthParticipated>0) & (!MergedDF$Participated)] <- "Does not participate"
	if (IncludeInfoOnNrMonthsHungry){
		#Only do this if respondent isn't hungry on first month he/she participates in survey
		#Bit complex because TempDF$Hungry[1] can be NA if TempDF$rCSI[1] is NA
		IsFirstNotHungry <- (!is.na(TempDF$Hungry[1])) & (!isTRUE(TempDF$Hungry[1])) #I've checked this and it works, but can this be simplified?
		
		if ((IsFirstNotHungry) & (sum(TempDF$Hungry>0,na.rm = TRUE))){  
			WhichRowFirstHunger <- which(MergedDF$Hungry)[1] #Note the [1], in case hungry on multiple occasions
			MergedDF$MonthBeforeAfterFirstHunger <- seq_along(MergedDF$Hungry)-WhichRowFirstHunger
			#So if WhichRowFirstHunger =2, then MergedDF$MonthBeforeAfterFirstHunger = -1,0,1,2,etc (First month where Hungry is the row where  MonthBeforeAfterFirstHunger==0)
		} else {
			MergedDF$MonthBeforeAfterFirstHunger <- NA_integer_
		}
	}
	if (IncludeStatusNextMonth){
		MergedDF$StatusNextMonth <- c(MergedDF$Status[2:(length(MergedDF$Status))],"Not known")
	}
	MergedDF
}

#checking if it works on one random respondent
ReturnInfoOnRespondentAndMonth(subset(SubsetTheData,RspID == "U-2499264119023936746"), AllTheValidSvyDate,TRUE)

#Using group_by & do() of dplyr to run ReturnInfoOnRespondentAndMonth for each respondent in SubsetTheData
#See https://blog.rstudio.org/2014/05/21/dplyr-0-2/ (found through http://stackoverflow.com/questions/24405239/ddply-dplyr-fun-summarize-with-several-rows?rq=1)
#Note the . in do()
SubsetWithMoreInfoPerRspAndMonth  <-  SubsetTheData %>% group_by(RspID) %>% do(ReturnInfoOnRespondentAndMonth(., AllTheValidSvyDate,TRUE))
table(table(SubsetWithMoreInfoPerRspAndMonth$RspID)) #Should only have one output


#This function gives just data about respondent, i.e. info which doesn't change throughout the dataset
#For general info about ReturnInfoOnRespondent, see above.
#Info on the input parameters:
#   InputDF:
#       data frame, containing info on one respondent only. 
#   ValidSvyDate:
#       vector of one or more Dates.
#       Only data from InputDF is used where SvyDateAsDate is in ValidSvyDate (note that NrMonthParticipated is computed while disregarding ValidSvyDate
#   MinrCSIHungry:
#       Someone is classified as being Hungry on a certain month if his/her rCSI on a month is higher than (or equal to) MinrCSIHungry.
#       Not sure if the standard value of 25 is OK.
#
#Info about the extra columns added to the output
#   For most inputs it creates two values. One (whose name ends with _First) is the value of that field on the first survey it participated in.
#   The second value (whose name ends with _Changed) is a Boolean that indicates whether this value has changed during the survey.
# 
#   RspID:
#       String. The ID of the respondent.
#   HungryOnFirstSurvey:
#       Boolean. Was the respondent hungry on the first month it participated in the survey?
#       If so, you can't use this respondent to find out what happens after someone is hungry for the first time
#       because it isn't known whether he/she was hungry on the previous month.

ReturnInfoOnRespondent <- function(InputDF,ValidSvyDate,MinrCSIHungry=25){
    stopifnot(c("SvyDateAsDate","RspID","rCSI","ADM0_NAME","ADM1_NAME","ADM2_NAME","Gender","HoHSex","ToiletType") %in% colnames(InputDF))
	TempDF <- InputDF[order(InputDF$SvyDateAsDate), ]
	TheRspId <- unique(InputDF$RspID)
	TempDF <- subset(TempDF, SvyDateAsDate %in% ValidSvyDate)
	
	TempDF$Hungry <- (TempDF$rCSI >= MinrCSIHungry)
	HungryOnFirstSurvey_tmp <- TempDF$Hungry[1] #Want to know this later for all the data.frame of this respondent 
	#Note that it's the first of TempDF (the ordered InputDF), so it's the first survey this respondent participated in.
	
	#I want to add info about participant to all columns. Because some might change I only output the first non NA value
	#and info whether it has changed.
	ADM0_NAME_NotNA <- na.omit(TempDF$ADM0_NAME)
	ADM0_NAME_First <- ADM0_NAME_NotNA[1]
	ADM0_NAME_Changed <- (length(unique(ADM0_NAME_NotNA))>1)

	ADM1_NAME_NotNA <- na.omit(TempDF$ADM1_NAME)
	ADM1_NAME_First <- ADM1_NAME_NotNA[1]
	ADM1_NAME_Changed <- (length(unique(ADM1_NAME_NotNA))>1)

	ADM2_NAME_NotNA <- na.omit(TempDF$ADM2_NAME)
	ADM2_NAME_First <- ADM2_NAME_NotNA[1]
	ADM2_NAME_Changed <- (length(unique(ADM2_NAME_NotNA))>1)	
	
	Gender_NotNA <- na.omit(TempDF$Gender)
	Gender_First <- Gender_NotNA[1]
	Gender_Changed <- (length(unique(Gender_NotNA))>1)	

	HoHSex_NotNA <- na.omit(TempDF$HoHSex)
	HoHSex_First <- HoHSex_NotNA[1]
	HoHSex_Changed <- (length(unique(HoHSex_NotNA))>1)

	#ToiletType is "" for some, removing those
	ToiletType_NotNA <- na.omit(TempDF$ToiletType[TempDF$ToiletType!=""])
	ToiletType_First <- ToiletType_NotNA[1]
	ToiletType_Changed <- (length(unique(ToiletType_NotNA))>1)
	data.frame(RspID =TheRspId, ADM0_NAME_First,ADM0_NAME_Changed,ADM1_NAME_First,ADM1_NAME_Changed,ADM2_NAME_First,ADM2_NAME_Changed,Gender_First,Gender_Changed,
		HoHSex_First,HoHSex_Changed,ToiletType_First,ToiletType_Changed,HungryOnFirstSurvey=HungryOnFirstSurvey_tmp,stringsAsFactors=FALSE)
}

#can this be done with summarise? Not sure, because of AllTheValidSvyDate
SubsetWithMoreInfoPerRsp  <-  SubsetTheData %>% group_by(RspID) %>% do(ReturnInfoOnRespondent(., AllTheValidSvyDate))

#Note the difference between the two
dim(SubsetWithMoreInfoPerRsp)
dim(SubsetWithMoreInfoPerRspAndMonth)

table(SubsetWithMoreInfoPerRsp$ADM2_NAME_Changed)

with(SubsetWithMoreInfoPerRspAndMonth, table(SvyDateAsDate,Status))
with(SubsetWithMoreInfoPerRspAndMonth, table(SvyDateAsDate,Status=="Participant"))

with(SubsetWithMoreInfoPerRspAndMonth, table(Status,StatusNextMonth,SvyDateAsDate))
with(SubsetWithMoreInfoPerRspAndMonth, table(Status=="Participant",StatusNextMonth=="Participant",SvyDateAsDate))
#Do I know if somebody wasn't phoned at all?


qplot(SvyDateAsDate,NrLines, col = Status,data =SubsetWithMoreInfoPerRspAndMonth %>% group_by(SvyDateAsDate,Status) %>% summarise(NrLines = n()))


################################################
#
# Check MonthBeforeAfterFirstHunger in SubsetWithMoreInfoPerRspAndMonth
# Also do some plots
#
################################################

table(SubsetWithMoreInfoPerRspAndMonth$MonthBeforeAfterFirstHunger,useNA = "ifany")

#using "normal R"
boxplot(rCSI~MonthBeforeAfterFirstHunger, data = SubsetWithMoreInfoPerRspAndMonth)

#and with ggplot
qplot(MonthBeforeAfterFirstHunger,rCSI,data = subset(SubsetWithMoreInfoPerRspAndMonth, !is.na(MonthBeforeAfterFirstHunger) & !is.na(rCSI)),geom=c("jitter","smooth"),method = "loess")
#Explanation of previous plot
#That the rCSI value on 'MonthBeforeAfterFirstHunger' of -1 is less than the MinrCSIHungry used in ReturnInfoOnRespondent is by design.
#Because MonthBeforeAfterFirstHunger = 0 is the first month where the rCSI was equal to (or higher than) MinrCSIHungry.
#So the dip on the left hand side at MonthBeforeAfterFirstHunger = -1 is understandable.
#
#The drop at the right hand side could indicate that people don't stay hungry for a long time
#But note that the data is biased because on the right hand side one only sees those who
# 1) weren't hungry on the first month contacted
# 2) did participate in the survey for several months
# 3) and they did participate in the survey for several months after their first hunger. I.e. they survived hunger & Ebola

#Next line doesn't order the subplots per month, yet
qplot(MonthBeforeAfterFirstHunger,rCSI,data = subset(SubsetWithMoreInfoPerRspAndMonth, !is.na(MonthBeforeAfterFirstHunger) & !is.na(rCSI)),geom=c("jitter","smooth"),method = "loess")+facet_wrap(~SvyDate)

#Another interesting approach is to plot a single line for each respondent. Then one sees gaps in the data.
#PlotCSIOfOneHungryParticipant is used for this.

PlotCSIOfOneHungryParticipant <- function(InputDF){ 
	TempDF <- subset(InputDF[order(InputDF$SvyDateAsDate), ],!is.na(MonthBeforeAfterFirstHunger))
	if (dim(TempDF)[1]>0){
		with(TempDF,lines(MonthBeforeAfterFirstHunger,rCSI,type="o"))
	}
	return(data.frame())
}

#TODO: explain these plots more?

with(SubsetWithMoreInfoPerRspAndMonth,plot(MonthBeforeAfterFirstHunger,rCSI,type="n"))
PlotCSIOfOneHungryParticipant(subset(SubsetWithMoreInfoPerRspAndMonth,RspID == "U-1030281186745689017"))

with(SubsetWithMoreInfoPerRspAndMonth,plot(MonthBeforeAfterFirstHunger,rCSI,type="n"))
TempDF  <-  SubsetWithMoreInfoPerRspAndMonth %>% group_by(RspID) %>% do(PlotCSIOfOneHungryParticipant(.))	
#Hmm, previous line gives an error:
#Error: upper value must be greater than lower value
#plot seems ok
#next line gives same error, traceback() doesn't give meaningful info
#TempDF  <-  subset(SubsetWithMoreInfoPerRspAndMonth,!is.na(MonthBeforeAfterFirstHunger)) %>% group_by(RspID) %>% do(PlotCSIOfOneHungryParticipant(.))	


################################################
#
# Important question: are those who are participant for a longer period better off (since they still have the same mobile phone)?
# Testing this per month per area 
# Or should I compare per month per area those who just participate with those who participated for a longer period?
#
################################################

#For those who participated in december 2015, do I see a lower rCSI for those who participated longer?
boxplot(rCSI~ NrMonthParticipated, data = subset(SubsetWithMoreInfoPerRspAndMonth,Status == "Participant" & SvyDateAsDate == as.Date("2015-12-01")))

summary(lm(rCSI ~ NrMonthParticipated,data = subset(SubsetWithMoreInfoPerRspAndMonth,Status == "Participant" & SvyDateAsDate == as.Date("2015-12-01"))))
#Nope, still not the case. Or do I need to include the area?
summary(lm(rCSI ~ NrMonthParticipated + ADM1_NAME,data = subset(SubsetWithMoreInfoPerRspAndMonth,Status == "Participant" & SvyDateAsDate == as.Date("2015-12-01"))))
#Not even then
#And what if I only look at those who participated in december 2015 for more than 3 months?
summary(lm(rCSI ~ NrMonthParticipated,data = subset(SubsetWithMoreInfoPerRspAndMonth,Status == "Participant" & SvyDateAsDate == as.Date("2015-12-01") & NrMonthParticipated > 3)))
summary(lm(rCSI ~ NrMonthParticipated + ADM1_NAME,data = subset(SubsetWithMoreInfoPerRspAndMonth,Status == "Participant" & SvyDateAsDate == as.Date("2015-12-01") & NrMonthParticipated > 3)))
#Still nothing

#There seems to be an indication that HoHSex = M lowers the rCSI
boxplot(rCSI ~ HoHSex, data = subset(SubsetWithMoreInfoPerRspAndMonth,Status == "Participant" & SvyDateAsDate == as.Date("2015-12-01")))

################################################
#
# To show what happens to respondents on multiple months I've looked at multiple 
# R libraries. I wanted a nice visualisation that allows one to see patterns in participating or not participating.
# At first I found http://stackoverflow.com/questions/34571899/sankey-diagram-in-r where network3d is mentioned. But there you 
# can't fix the x-axis position; only the strength can be given. 
# One can look at http://stackoverflow.com/questions/21539265/d3-sankey-charts-manually-position-node-along-x-axis for some ways to do it.
# But it's still difficult.
#
# Decided I wanted to make an Alluvial diagram (see https://en.wikipedia.org/wiki/Alluvial_diagram)
# Had a look at alluvial (see http://bc.bojanorama.pl/2014/03/alluvial-diagrams/) and riverplot (on CRAN)
# But the input required for riverplot is much more complex than the simple data.frame used by alluvial
# and only alluvial can track those that have a certain status on a certain surveydate.
# 
################################################

#The dataframes such as SubsetWithMoreInfoPerRspAndMonth contain info about each respondent on multiple lines (one line
#per month). That's not the input alluvial requires. Alluvial requires a format where all the info about the different
#"attributes" is on one line. A separate input to alluvial is a vector (named Freq) with number of occurrences of each line.
#So I need to transform
# SvyDateAsDate RspID Status
#    2015-10-01   123  Participant
#    2015-11-01   123  Participant
#    2015-10-01   342  Does not participate
#    2015-11-01   342  Participant
#    2015-10-01   651  Does not participate
#    2015-11-01   651  Participant
# to
#           2015-10-01  2015-11-01 Freq
#          Participant Participant    1
# Does not participate Participant    2
# 
#It's possible that the newer 'tidyverse' libraries could also be used to convert between these formats.
#But here I use CombineDataForAlluvial below, which uses reshape2
 

#For general info about CombineDataForAlluvial, see above.
#It requires two dataframes:
#1) one with info about each combination of month & respondent (such as SubsetWithMoreInfoPerRspAndMonth)
#2) one with info about each respondent (such as SubsetWithMoreInfoPerRsp) 
#This to allow the user to plot info from both data frames.

#Info on the input parameters:
#    DFWithInfoPerRspAndMonth (A dataframe such as SubsetWithMoreInfoPerRspAndMonth)
#    DFWithMoreInfoPerRsp (A dataframe such as SubsetWithMoreInfoPerRsp)
#    ExtraColumnsToAdd:
#		An optional vector of characters, telling which extra columns to add, e.g. c("ToiletType_First","ADM2_NAME_First")
#       This vector has to contain column names from either DFWithInfoPerRspAndMonth, DFWithMoreInfoPerRsp or both.
#    UseTheseMonths:
#       An optional vector of characters, showing the months to use in the output, e.g. c("2015-10-01","2015-11-01")
#       If not used (i.e. NA) then all months found in data are used.
#
#Output
#   Output is data frame with the required format.

CombineDataForAlluvial <- function(DFWithInfoPerRspAndMonth,  DFWithMoreInfoPerRsp,ExtraColumnsToAdd = NA,UseTheseMonths= NA){
	stopifnot(c("SvyDateAsDate","RspID","Status") %in% colnames(DFWithInfoPerRspAndMonth))
	stopifnot(c("RspID") %in% colnames(DFWithMoreInfoPerRsp))
	#I don't need to check that there is only one Status per month per SvyDate, because that's so on purpose
	#well, just in case
	stopifnot(dim(DFWithInfoPerRspAndMonth %>% group_by(SvyDateAsDate,RspID) %>% summarise(NrLines = n()) %>% filter(NrLines>1))[1]==0)
	
	#The following line (using commands from reshape2) makes this data "wide" with one column per month and one row per RspID
	#the extra function (function(x){x[1]}) ensures that it always picks the first value per combination of RspID & SvyDateAsDate
	#dcast doesn't know that there is always just one value. One could probably use head with n=1 instead of function(x){x[1]}.
	StatusPerRspID_ColumnPerMonth <- dcast(data = DFWithInfoPerRspAndMonth[,c("SvyDateAsDate","RspID","Status")],RspID~SvyDateAsDate,function(x){x[1]},value.var="Status")
	#Need to merge these with DFWithMoreInfoPerRsp
	#RspID should be same in both. Check this.
	stopifnot(sum(!(StatusPerRspID_ColumnPerMonth$RspID %in% DFWithMoreInfoPerRsp$RspID))==0)
	stopifnot(sum(!( DFWithMoreInfoPerRsp$RspID %in% StatusPerRspID_ColumnPerMonth$RspID))==0)
	#It is
	mergedDF <- merge(StatusPerRspID_ColumnPerMonth,DFWithMoreInfoPerRsp)

	#If UseTheseMonths = NA then pick all the months available in mergedDF
	#Otherwise pick columns mentioned in UseTheseMonths
	if (sum(is.na(UseTheseMonths)==1) & length(UseTheseMonths)==1){
		
		TheColumnsPartOne <- grep("[0-9]{4}-[0-9]{2}-[0-9]{2}",colnames(mergedDF),value = TRUE) #Everything in colnames of mergedDF that has the format 9999-99-99
	} else {
		stopifnot(length(UseTheseMonths)>0)
		stopifnot(class(UseTheseMonths)=="character") 
		stopifnot(sum(is.na(UseTheseMonths))==0)
		stopifnot(UseTheseMonths %in% colnames(mergedDF))
		TheColumnsPartOne <- UseTheseMonths
	} #end else
	#If ExtraColumnsToAdd = NA, then don't get any extra columns
	#otherwise get the columns from ExtraColumnsToAdd
	if (sum(is.na(ExtraColumnsToAdd)==1) & length(ExtraColumnsToAdd)==1){
		TheColumnsPartTwo <- NULL
	} else {
	    stopifnot(length(ExtraColumnsToAdd)>=0)
		stopifnot(class(ExtraColumnsToAdd)=="character") 
		stopifnot(sum(is.na(ExtraColumnsToAdd))==0)
		stopifnot(ExtraColumnsToAdd %in% colnames(mergedDF))
		TheColumnsPartTwo <- ExtraColumnsToAdd
	} #end else
		
	#Just pick the required columns from mergedDF
	#Note that regroup requires a list
	DataForAlluv <- mergedDF %>% regroup(as.list(c(TheColumnsPartOne,TheColumnsPartTwo))) %>% summarise(Freq=n())
	
	#alluvial doesn't handle NA in the data well, so replacing it (unless it's in DataForAlluv, which shouldn't
	#be, but testing just in case
	stopifnot(sum(is.na(DataForAlluv$Freq))==0)
	DataForAlluv[is.na(DataForAlluv)] <- "N.A."
	DataForAlluv
} #

TestDataAlluv <- CombineDataForAlluvial(SubsetWithMoreInfoPerRspAndMonth,SubsetWithMoreInfoPerRsp,ExtraColumnsToAdd = "ADM1_NAME_First")
#It can also be used as
TestDataAlluv2 <- CombineDataForAlluvial(SubsetWithMoreInfoPerRspAndMonth,SubsetWithMoreInfoPerRsp,UseTheseMonths=c("2015-10-01","2015-11-01"))

TestDataAlluv3 <- CombineDataForAlluvial(SubsetWithMoreInfoPerRspAndMonth,SubsetWithMoreInfoPerRsp)

TestDataAlluv4 <- CombineDataForAlluvial(SubsetWithMoreInfoPerRspAndMonth,SubsetWithMoreInfoPerRsp,UseTheseMonths=c("2015-10-01","2015-11-01"),ExtraColumnsToAdd=c("ToiletType_First","ADM1_NAME_First"))

#This can be plotted as
alluvial(subset(TestDataAlluv2,select = -Freq),freq=TestDataAlluv2$Freq)

#CombineDataForAlluvial outputs both inputs needed for alluvial (a data frame and a vector) as a single data frame
#This to ensure that it's relatively easy to take subsets of both inputs in a consistent way. Below
#alluvial is called twice, once for those participants who participated first from the Eartern Area, and once
#for those participants who participated first from the Northern Area. 
#Note the use of col with an ifelse() command to give lines a colour depending on the status in 2015-10-01.

par(mfcol=c(2,1))
ASubset <- subset(TestDataAlluv4, ADM1_NAME_First == "Eastern")
alluvial(subset(ASubset, select = -Freq),freq=ASubset$Freq,col=ifelse( ASubset$`2015-10-01`=="Participant", "red", "gray"))
ASubset <- subset(TestDataAlluv4, ADM1_NAME_First == "Northern")
alluvial(subset(ASubset, select = -Freq),freq=ASubset$Freq,col=ifelse( ASubset$`2015-10-01`=="Participant", "red", "gray"))
par(mfcol=c(1,1))

#Which can be compared with the next line, where all 4 ADM1_NAME_First are used.
alluvial(subset(TestDataAlluv4, select = -Freq),freq=TestDataAlluv4$Freq,col=ifelse( TestDataAlluv4$`2015-10-01`=="Participant", "red", "gray"))

################################################
#
# TraMineR is "a toolbox for the manipulation, description and rendering of sequences."
# It is used when analysing lifecycles, where each subject can be in one sequence (single, married, etc.).
# Here the possibilities are "Does not participate", "Has not participated yet" and "Participant".
# Below I merely show a tiny bit of what's possible with TraMineR. The vignette (38 pages) shows much more!
#
################################################


#Or use TraMineR package (see there sortv & cmdscale, seqtrade (time.varying= TRUE) en seqdplot)
#For TraMineR: StatusPerRspID_ColumnPerMonth seems to be in the STS format. 
library(TraMineR)


#The TraMineR package can read many different formats of data. The line below (based on a line from CombineDataForAlluvial above)
#creates a dataset which is in the "STS" format described in table 4 of the TraMineR vignette.
mergedDF_ForTraMineR <-  merge(dcast(data = SubsetWithMoreInfoPerRspAndMonth[,c("SvyDateAsDate","RspID","Status")],RspID~SvyDateAsDate,function(x){x[1]},value.var="Status"),SubsetWithMoreInfoPerRsp)
#Then the "STS" data is read and a TraMineR object (PerRspIDTraMineR) is created.
PerRspIDTraMineR <- seqdef(mergedDF_ForTraMineR,colnames(mergedDF_ForTraMineR)[grep("[0-9]{4}-[0-9]{2}-[0-9]{2}",colnames(mergedDF_ForTraMineR))]) 

#Different plots are possible
seqdplot(PerRspIDTraMineR)
seqdplot(PerRspIDTraMineR,group = mergedDF_ForTraMineR$ADM1_NAME_First)
seqdplot(PerRspIDTraMineR,group = mergedDF_ForTraMineR$Gender_First)

#TraMineR can also compute the rate in which respondents move from one state to the next:  
seqtrate(PerRspIDTraMineR,time.varying= TRUE)

#And it can also cluster the respondents based on their behaviour. The following example is adapted
#from the vignette.
 
#"[here we c]ompute pairwise optimal matching (OM) distances between sequences with an
#insertion/deletion cost of 1 and a substitution cost matrix based on
#observed transition rates:"
PerRspIDTraMineR.om <- seqdist(PerRspIDTraMineR, method = "OM", indel = 1, sm = "TRATE")
#Then, using this distance matrix, compute the clusters of similar sequence and get the 4 clusters
library("cluster")
clusterward <- agnes( PerRspIDTraMineR.om, diss = TRUE, method = "ward")
PerRspIDTraMineR.cl4 <- cutree(clusterward, k = 4)
cl4.lab <- factor(PerRspIDTraMineR.cl4, labels = paste("Cluster", 1:4))
#And the plot the 4 clusters
seqdplot(PerRspIDTraMineR, group = cl4.lab, border = NA)
#Note however that "[a] state distribution plot, as produced by seqdplot(), displays the general pattern of the
#whole set of trajectories. When interpreting such graphics, one must remember that, unlike
#sequence index plots and sequence frequency plots, they do not render individual sequences ..."

#That's all folks!
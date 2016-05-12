library(RNetCDF)
nc <- open.nc("chirps-v2.0.2015.days_p25.nc")
print.nc(nc) # print for information
nc_data <- read.nc(nc) # actually read data
precip <- nc_data$precip # take the 3d precipitation matrix
# add the names for the dimensions for the next step
dimnames(precip)<-list(d1=nc_data$longitude, d2=nc_data$latitude, d3=nc_data$time)
# now when we convert this to a table the dimnames will be automatically set
df <- as.data.frame.table(precip, responseName = "value", stringsAsFactors = FALSE)
# there seem to be quite a few missing values
relevant <- df[!is.na(df$value) & df$value!=0, ]
colnames(relevant) <- c("longitude", "latitude", "time", "value")
relevant$latitude <- as.numeric(relevant$latitude)
relevant$longitude <- as.numeric(relevant$longitude)
relevant$time <- as.numeric(relevant$time)

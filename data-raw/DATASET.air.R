## code to prepare `DATASET` dataset goes here
# Python airdb package must be installed to run this code.
library(xts)
library(reticulate)
library(reshape2)


city <- "isparta"
params <- c('pm10', 'so2')

# Import airdb package from python
airdb <- import("airdb", convert = TRUE)

# Connect to DB
db <- airdb$Database('air', 'df')

# Query Database
df <- db$query(params, city = city, sta = city)

# Prepare dataset
df$param <- as.factor(df$param)
df$value[is.nan(df$value)] <- NA
df_wide <- reshape(df, timevar = "param", idvar = "date", v.names = "value",
                   direction = "wide")
colnames(df_wide)[4:(4 + length(params) - 1)] <- params
df_wide <- df_wide[,-(1:2)]
x <- xts(df_wide[,-1], order.by = df_wide$date, tzone = 'GMT')

# This is the first part of the data
x <- x["2010/2020"]
isp.air1 <- cbind(date = zoo::index(x), as.data.frame(x))
rownames(isp.air1) <- NULL

# Read the second part from a csv file.
isp.air2 <- read.csv("data-raw/csv/air_2021.csv")
isp.air2$date <- as.POSIXct(isp.air2$date, tz = "GMT")

isp.air <- rbind(isp.air1, isp.air2)

usethis::use_data(isp.air, overwrite = TRUE)

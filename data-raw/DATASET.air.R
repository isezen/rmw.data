## code to prepare `DATASET` dataset goes here
# Python airdb package must be installed to run this code.
library(xts)
library(reticulate)
library(reshape2)

read_data <- function(city, params, db = 'met') {

  # Import airdb package from python
  airdb <- import("airdb", convert = TRUE)

  # Connect to DB
  db <- airdb$Database(db, 'df')

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
  x <- x["2010/2021"]

  isp.met <- cbind(date = zoo::index(x), as.data.frame(x))
  rownames(isp.met) <- NULL
  return(isp.met)
}

read_air <- function() {
  isp.air1 <- read_data('isparta', c('pm10', 'so2'), 'air')
  isp.air1 <- zoo::na.trim(isp.air1)

  # Read the second part from a csv file.
  isp.air2 <- read.csv("data-raw/csv/air_2021.csv")
  isp.air2$date <- as.POSIXct(isp.air2$date, tz = "GMT")

  rbind(isp.air1, isp.air2)
}


isp.air <- read_air()

usethis::use_data(isp.air, overwrite = TRUE)

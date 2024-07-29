## code to prepare `DATASET` dataset goes here
# Python airdb package must be installed to run this code.

library(xts)
library(ncdf4)
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

read_blh_from_netcdf <- function(filename, target_lat, target_lon) {
  # Open the netCDF file
  ncfile <- nc_open(filename)

  # Read the longitude, latitude, and time variables
  lon <- ncvar_get(ncfile, "longitude")
  lat <- ncvar_get(ncfile, "latitude")
  time <- ncvar_get(ncfile, "time")

  # Find the nearest indices for the target coordinates
  lon_idx <- which.min(abs(lon - target_lon))
  lat_idx <- which.min(abs(lat - target_lat))

  # Read the BLH data for the nearest grid point
  blh <- ncvar_get(ncfile, "blh", start = c(lon_idx, lat_idx, 1), count = c(1, 1, -1))

  # Convert the time variable to human-readable dates
  # ERA5 time is in hours since 1900-01-01 00:00:00
  dates <- as.POSIXct("1900-01-01 00:00:00", tz = "UTC") + time * 3600

  # Close the netCDF file
  nc_close(ncfile)

  isp.blh <- data.frame(date = dates, blh = blh)
  return(isp.blh)
}

read_blh_from_csv <- function(filename) {
  x <- read.csv(filename)
  colnames(x) <- c("date", "blh")
  x$date <- as.POSIXct(x$date, tz = "GMT")
  return(x)
}

# Read meteorogy data
params <- c('temp', 'wspd', 'wdir', 'rh', 'precp', 'apres')
isp.met <- read_data("isparta", params, 'met')

# read BLH data
# TODO: Read from netcf file
isp.blh <- read_blh_from_csv("data-raw/csv/blh.csv")
isp.met <- merge(isp.met, isp.blh, by = "date", all = FALSE)

usethis::use_data(isp.met, overwrite = TRUE)

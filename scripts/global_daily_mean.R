library(ggplot2)
library(data.table)
library(metR)
library(lubridate)
library(unglue)

file_na <- Sys.glob("/scratch/w40/pc2687/2t_gt_p99_na.nc")
file_data <- "/scratch/w40/pc2687/2t_daily_deseasoned.nc"

times <- seq.Date(as_date("1970-01-01"), as_date("2023-12-31"), "days")

t2_mean <- purrr::map(times, function(t) {
  
  message(t)
  
  nas <- ReadNetCDF(file_na, vars = "t2m", subset = list(time = as_date(t)),
                    out = "vector")
  
  t2 <- ReadNetCDF(file_data, vars = "t2m", subset = list(time = as_date(t))) |> 
    _[, na := nas] |> 
    _[, t2m := t2m*na] |> 
    _[, .(t2m = mean(t2m, na.rm = TRUE)), by = time]
  
}) |> 
  rbindlist()



readr::write_rds(t2_mean, "~/ve-project/data/t2_mean_daily_p99.rds")


# ReadNetCDF(file_data, vars = "t2m", subset = list(time = as_date(t))) |> 
#   ggplot(aes(longitude, latitude)) +
#   scattermore::geom_scattermore(aes(color =  t2m))
# 
# ReadNetCDF(file_na, vars = "t2m", subset = list(time = as_date(t))) |> 
#   ggplot(aes(longitude, latitude)) +
#   scattermore::geom_scattermore(aes(color =  t2m))
# 
# t2 |> 
#   ggplot(aes(longitude, latitude)) +
#   scattermore::geom_scattermore(aes(color =  t2m))
# t2_mean <- readr::read_rds("data/t2_mean.rds")
# 
# global_mean  <- t2_mean$global_mean |>
#   _[, t2m_a := t2m - mean(t2m), by = .(month(time))] |> 
#   _[, time := as_datetime(time, tz = "UTC")]

library(ggplot2)
library(lubridate)
library(data.table)
library(unglue)
library(metR)

years <- 1970:2020

file_list  <- Sys.glob(paste0("/g/data/rt52/era5/single-levels/reanalysis/2t/", years, "/*"))

files <- unglue_data(basename(file_list), "2t_era5_oper_sfc_{start}-{end}.nc") |> 
  setDT() |> 
  _[, let(file_name = file_list,
          start = ymd(start),
          end = ymd(end))]

dates <- seq(ymd(19700101), ymd(20201231), by = "days")


purrr::map(dates, function(l) {
  
  
  this_file <- files[year(start) == year(l) & month(start) == month(l)]

  
  ReadNetCDF(this_file$file_name, subset = list(time = paste(l, "12:00:00"))) |> 
    _[, .(t2m = mean(t2m)), by = time]
  
}) |> 
  rbindlist() |>
  readr::write_rds("data/t2m_daily_mean.rds")



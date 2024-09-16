library(ggplot2)
library(data.table)
library(metR)
library(lubridate)
library(unglue)

strong <- readr::read_rds("~/ve-project/data/strong_volcanos.rds")

center_day <- 180
half_window <- 60 # 30 is 2 months

times <- purrr::map(strong$ini_date, function(d) {
  
  d <- d + days(center_day)
  list(seq.Date(d - days(half_window), d + days(half_window), by = "day"))
  
}) |> rbindlist() |> 
  _[, .(time = unique(V1))]

for (t in times$time) {
  
  message(t)
  if (t == times$time[1]) {
    
    temp <- ReadNetCDF("/scratch/w40/pc2687/tp_daily_deseasoned.nc", vars = "tp", subset = list(time = as_date(t)))
    
    temp[, time := NULL]
    
  } else {
    
    field <- rbind(temp, 
                   ReadNetCDF("/scratch/w40/pc2687/tp_daily_deseasoned.nc", vars = "tp", subset = list(time = as_date(t))) |> 
                     _[, time := NULL])  |> 
      _[, .(tp = sum(tp)), by = .(longitude, latitude)]
  }
  
}
field[, let(tp = tp/nrow(times))] |> 
  readr::write_rds(x = _, paste0("~/ve-project/data2/tp_a", center_day/30, "m_", half_window*2/30, "m_composite_all.rds"))

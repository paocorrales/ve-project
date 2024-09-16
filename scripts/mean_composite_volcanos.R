library(ggplot2)
library(data.table)
library(metR)
library(lubridate)
library(unglue)

strong <- readr::read_rds("~/ve-project/data/strong_volcanos.rds")

center_day <- 180
half_window <- 30 # 30 is 2 months


for (v in strong$volcano) {
  
  message(v)
  d <- strong[volcano == v]$ini_date + days(center_day)
  
  times <- seq.Date(d - days(half_window), d + days(half_window), by = "day")
  # times <- seq.Date(d - days(365), d - days(1), by = "days")
  
  
  for (t in times) {
    
    message(t)
    if (t == times[1]) {
      
      temp <- ReadNetCDF("/scratch/w40/pc2687/tp_daily_deseasoned.nc", vars = "tp", subset = list(time = as_date(t)))
      
      temp[, time := NULL]
      
    } else {
      
      field <- rbind(temp, 
                     ReadNetCDF("/scratch/w40/pc2687/tp_daily_deseasoned.nc", vars = "tp", subset = list(time = as_date(t))) |> 
                       _[, time := NULL])  |> 
        _[, .(tp = sum(tp)), by = .(longitude, latitude)]
    }
    
  }
  field[, let(tp = tp/length(times),
              volcano = v)] |> 
    readr::write_rds(x = _, paste0("~/ve-project/data2/tp_a", center_day/30, "m_", half_window*2/30, "m_composite_", v, ".rds"))
}


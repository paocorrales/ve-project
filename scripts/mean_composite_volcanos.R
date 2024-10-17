library(ggplot2)
library(data.table)
library(metR)
library(lubridate)
library(unglue)

strong <- readr::read_rds("~/ve-project/data/strong_volcanos.rds")

var <- "2t"
center_day <- 180
half_window <- 60 # 30 is 2 months
period <- "after_ve" # base / after_ve


for (v in strong$volcano) {
  
  message(v)
  if (var == "2t") {
    var2 <- "t2m"
  } else {
    var2 <- var
  }
  
  if (period == "base") {
    d <- strong[volcano == v]$ini_date
    times <- list(seq.Date(d - days(365), d + days(0), by = "day"))
  } else {
    d <- strong[volcano == v]$ini_date + days(center_day)
    times <- seq.Date(d - days(half_window), d + days(half_window), by = "day")
  }
  
  for (t in times) {
    
    message(t)
    file <- paste0("/g/data/w40/pc2687/ve/data_noenso/anomaly/", var, "_", formatC(month(as_date(t)), width = 2, flag = "0"), "_anomaly_mei.nc")
    
    if (t == times[1]) {
      
      field <- ReadNetCDF(file, vars = var2, subset = list(time = as_date(t))) |> 
        setnames(var2, "value") |> 
        _[, .(latitude, longitude, value)]
      
    } else {
      
      field <- rbind(field,
                     ReadNetCDF(file, vars = var2, subset = list(time = as_date(t))) |>
                       setnames(var2, "value") |>
                       _[, .(latitude, longitude, value)])  |>
        _[, .(value = sum(value)), by = .(longitude, latitude)]
    }
    
  }
  
  if (period == "base") {
    field[, let(value = value/nrow(times),
                volcano = v)] |> 
      setnames("value", var2) |> 
      readr::write_rds(x = _, paste0("~/ve-project/data_noenso/derived/", var, "_base_composite_", v, ".rds"))
  } else {
    
    field[, let(value = value/nrow(times),
                volcano = v)] |> 
      setnames("value", var2) |> 
      readr::write_rds(x = _, paste0("~/ve-project/data_noenso/derived/", var, "_a", center_day/30, "m_", half_window*2/30, "m_composite_", v, ".rds"))
  }
  
}


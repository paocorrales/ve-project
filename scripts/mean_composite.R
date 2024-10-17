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

times <- purrr::map(strong$ini_date, function(d) {
  
  if (period == "base") {
    times <- list(seq.Date(d - days(365), d + days(0), by = "day"))
  } else {
    d <- d + days(center_day)
    times <- list(seq.Date(d - days(half_window), d + days(half_window), by = "day"))
  }
  
  times
}) |> rbindlist() |> 
  _[, .(time = V1)]

for (t in times$time) {
  
  message(t)
  if (var == "2t") {
    var2 <- "t2m"
  } else {
    var2 <- var
  }
  
  file <- paste0("/g/data/w40/pc2687/ve/data_noenso/anomaly/", var, "_", formatC(month(as_date(t)), width = 2, flag = "0"), "_anomaly_mei.nc")
  
  if (t == times$time[1]) {
    
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
  field[, let(value = value/nrow(times))] |> 
    setnames("value", var2) |> 
    readr::write_rds(x = _, paste0("~/ve-project/data_noenso/derived/", var, "_base_composite_all.rds"))
} else {
  
  field[, let(value = value/nrow(times))] |> 
    setnames("value", var2) |> 
    readr::write_rds(x = _, paste0("~/ve-project/data_noenso/derived/", var, "_a", center_day/30, "m_", half_window*2/30, "m_composite_all.rds"))
}

library(ggplot2)
library(data.table)
library(metR)
library(lubridate)
library(unglue)

file_list  <- Sys.glob("/scratch/w40/pc2687/daily_means/2t/*")

GlanceNetCDF(file_list[1])

# future::plan(future::multisession, workers = 2)



t2_mean <- purrr::map(file_list, function(l) {
  
  message(basename(l))
  
  t2 <- ReadNetCDF(l, vars = "t2m")
  
  tropics <- t2[latitude %between% c(-30, 30), .(t2m = mean(t2m, na.rm = TRUE)), by = time]
  
  extratropics_n  <- t2[latitude %between% c(30, 60), 
                        .(t2m = mean(t2m, na.rm = TRUE)), by = time]
  
  extratropics_s  <- t2[latitude %between% c(-60, -30), 
                        .(t2m = mean(t2m, na.rm = TRUE)), by = time]
  
  austrlia  <- t2[longitude %between% c(110, 160) & latitude %between% c(-45, -10), 
                  .(t2m = mean(t2m, na.rm = TRUE)), by = time]
  
  list(tropics = tropics, 
       extratropics_n = extratropics_n,
       extratropics_s = extratropics_s,
       austrlia = austrlia)
  
}) |> 
  purrr::reduce(function(x, y) list(tropics = rbind(x$tropics, y$tropics),
                                    extratropics_n = rbind(x$extratropics_n, y$extratropics_n),
                                    extratropics_s = rbind(x$extratropics_s, y$extratropics_s),
                                    austrlia = rbind(x$austrlia, y$austrlia)))



readr::write_rds(t2_mean, "~/ve-project/data/t2_mean_daily_regions.rds")

# t2_mean <- readr::read_rds("data/t2_mean.rds")
# 
# global_mean  <- t2_mean$global_mean |>
#   _[, t2m_a := t2m - mean(t2m), by = .(month(time))] |> 
#   _[, time := as_datetime(time, tz = "UTC")]
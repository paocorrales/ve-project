library(ggplot2)
library(lubridate)
library(data.table)
library(unglue)
library(metR)

percentiles <- c(1, 5, 95, 99)

for (p in percentiles) {

file <- Sys.glob(paste0("/scratch/w40/pc2687/2t_*_p", p, ".nc"))

times <- seq.Date(as_date("19700101"), as_date("20231231"), by = "day")

message(p)

n_px <- purrr::map(times, function(t) {

  message(t)

  t2 <- ReadNetCDF(file, vars = "t2m", subset = list(time = as_date(t)))

  global <-  t2[, .(n_px = sum(t2m, na.rm = TRUE)), by = time]

  no_poles <- t2[latitude %between% c(-60, 60), .(n_px = sum(t2m, na.rm = TRUE)), by = time]

  tropics <- t2[latitude %between% c(-30, 30), .(n_px = sum(t2m, na.rm = TRUE)), by = time]

  extratropics_n  <- t2[latitude %between% c(30, 60),
                        .(n_px = sum(t2m, na.rm = TRUE)), by = time]

  extratropics_s  <- t2[latitude %between% c(-60, -30),
                        .(n_px = sum(t2m, na.rm = TRUE)), by = time]

  austrlia  <- t2[longitude %between% c(110, 160) & latitude %between% c(-45, -10),
                  .(n_px = sum(t2m, na.rm = TRUE)), by = time]


  list(global = global,
       no_poles = no_poles,
       tropics = tropics,
       extratropics_n = extratropics_n,
       extratropics_s = extratropics_s,
       austrlia = austrlia)

}) |>
  purrr::reduce(function(x, y) list(global = rbind(x$global, y$global),
                                    no_poles = rbind(x$no_poles, y$no_poles),
                                    tropics = rbind(x$tropics, y$tropics),
                                    extratropics_n = rbind(x$extratropics_n, y$extratropics_n),
                                    extratropics_s = rbind(x$extratropics_s, y$extratropics_s),
                                    austrlia = rbind(x$austrlia, y$austrlia)))


readr::write_rds(n_px, paste0("~/ve-project/data2/2t_p", p, "_npx.rds"))

}
# 
# p95 <- ReadNetCDF("/scratch/w40/pc2687/gt_p95/2t/95p/daily_2t_gt_p95_197001.nc", vars = "t2m", 
#                   subset = list(time = ymd_hms("1970-01-31 11:00:00")))
# 
# p5 <- ReadNetCDF("/scratch/w40/pc2687/gt_p95/2t/5p/daily_2t_gt_p5_197001.nc", vars = "t2m", 
#                  subset = list(time = ymd_hms("1970-01-31 11:00:00")))
# 
# p95[p5, on = .(time, latitude, longitude)] |> 
#   _[, diff := t2m - i.t2m] |> 
#   _[, sum(diff)]

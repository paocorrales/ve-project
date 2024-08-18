library(ggplot2)
library(lubridate)
library(data.table)
library(unglue)
library(metR)

n <- 5

file_list <- Sys.glob(paste0("/scratch/w40/pc2687/gt_p95/2t/", n, "p/*"))

n_px <- purrr::map(file_list, function(f) {
  
  message(basename(f))
  
  ReadNetCDF(f, vars = "t2m") |> 
    _[, .(n_px = sum(t2m)), by = time]
  
}) |> 
  rbindlist()


readr::write_rds(n_px, paste0("data/2t_gt_p", n, "_npx.rds"))

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

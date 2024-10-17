library(metR)
library(lubridate)
library(data.table)
library(rcdo)
source("help-functions.R")

## Create ENSO data
## Monthly data

message("Create ENSO data")

a <- ReadNetCDF(here::here("data_noenso/MEI/meiv2.nc")) |> 
  setnames("value", "mei") |> 
  agroclimatico::completar_serie(datos = _, time, resolucion = "1 dia") |> 
  setDT() |> 
  _[, mei := nafill(mei, "locf")]


purrr::map(1:12, function(m) {
  
  outfile <- here::here(paste0("data_noenso/MEI/mei_", formatC(m, width = 2, flag = "0"), ".nc"))
  
  if (file.exists(outfile)) {
    return(outfile)
  }
  
  a[month(time) == m & year(time) < 2024] |> 
    metR:::WriteNetCDF(data = _, file = outfile, vars = "mei")
  
})

# mei_01 <- ReadNetCDF("data_noenso/mei_01.nc")

## Enlarged
## 

message("Enlarged ENSO data")

grid <- "/g/data/w40/pc2687/ve/a_2t_daily.nc"

purrr::map(1:12, function(m) {
  
  message(m)
  
  outfile <-  here::here(paste0("data_noenso/MEI/mei_", formatC(m, width = 2, flag = "0"), "_enlarged.nc"))
  
  if (file.exists(outfile)) {
    return(outfile)
  }
  
  infile <- Sys.glob(paste0("data_noenso/MEI/mei_", formatC(m, width = 2, flag = "0"), ".nc"))
  
  infile |> 
    cdo_enlarge(
      grid
    ) |> 
    cdo_execute(output = outfile, options = "-L")
  
})

## ENSO statistics

message("Calculate ENSO statistics")

purrr::map(1:12, function(m) {
  
  message(m)
  
  infile <- here::here(paste0("data_noenso/MEI/mei_", formatC(m, width = 2, flag = "0"), "_enlarged.nc"))
  outfile <- here::here(paste0("data_noenso/MEI/mei_", formatC(m, width = 2, flag = "0"), "_var.nc"))
  
  if (file.exists(outfile)) {
    return(outfile)
  }
  
  infile |> 
    cdo_timvar() |> 
    cdo_execute(output = outfile, options = "-L")
  
  outfile <- here::here(paste0("data_noenso/MEI/mei_", formatC(m, width = 2, flag = "0"), "_mean.nc"))
  
  if (file.exists(outfile)) {
    return(outfile)
  }
  
  infile |> 
    cdo_timmean() |> 
    cdo_execute(output = outfile, options = "-L")
})


# a <- ReadNetCDF(outfile, subset = list(time = list(as_date("1979-01-01"), as_date("1981-01-01"))))

## Monthly variable maker
## 
## daily

future::plan(future::multisession, workers = 4)

message("daily data")

var <- "tp"
level <- "sfc"

temp_path <- "/scratch/w40/pc2687/daily_means/"


# purrr::map(1:12, function(m) {
#   
#   message(m)
#   
#   infile <- path_to_era5(var, level, months = m)
#   
#   if (var == "tp") {
#     daily_summary <- cdo_daysum
#   } else {
#     daily_summary <- cdo_daymean
#   }
#   
#   furrr::future_map(infile, function(f) {
#     
#     message(f)
#     
#     outfile <-  paste0(temp_path, var, "/daily_", basename(f))
#     
#     if (file.exists(outfile)) {
#       return(outfile)
#     }
#     
#     f |> 
#       daily_summary() |> 
#       cdo_execute(output = outfile, options = "-L")
#     
#   })
#   
# })

## Merge monthly files

# message("Merge data")
# 
# temp_path <- "/scratch/w40/pc2687/monthly/"
# 
# files <- data.table(file_names = Sys.glob(paste0("/scratch/w40/pc2687/daily_means/", var, "/*"))) |> 
#   _[, date := as_date(stringr::str_extract(file_names, "\\d{8}"))] 
# 
# purrr::map(1:12, function(m) {
#   
#   message(m)
#   
#   outfile <-  paste0(temp_path, var, "/", var, "_", formatC(m, width = 2, flag = "0"), ".nc")
#   dir.create(dirname(outfile), showWarnings = FALSE, recursive = TRUE)
#   
#   if (file.exists(outfile)) {
#     return(outfile)
#   }
#   
#   cdo_mergetime(files[month(date) == m, file_names]) |> 
#     cdo_execute(output = outfile, options = "-L -b F64")
# })

## Chunk anomalies
## 

message("Chunk anomalies")

temp_path <- "/g/data/w40/pc2687/ve/monthly/"

purrr::map(1:12, function(m) {
  
  message(m)
  
  infile <- paste0("/g/data/w40/pc2687/ve/", var, "_daily_deseasoned.nc")
  
  outfile <-  paste0(temp_path, var, "/", var, "_", formatC(m, width = 2, flag = "0"), ".nc")
  dir.create(dirname(outfile), showWarnings = FALSE, recursive = TRUE)
  
  if (file.exists(outfile)) {
    return(outfile)
  }
  list_years <- paste0(c(1979:2023), collapse = ",")
  
  infile |> 
    cdo_selmonth(months = m) |> 
    cdo_selyear(years = list_years) |> 
    cdo_execute(output = outfile, options = "-L -b F64")
})

## Pendiente
## 

message("Pendiente")

purrr::map(1:12, function(m) {
  
  message(m)
  
  outfile_a <- here::here(paste0("data_noenso/a/", var, "_mei_a_", formatC(m, width = 2, flag = "0"), ".nc"))
  
  if (file.exists(outfile_a)) {
    return(outfile_a)
  }
  
  infile_enso <- here::here(paste0("data_noenso/MEI/mei_", formatC(m, width = 2, flag = "0"), "_enlarged.nc"))
  infile_var <- paste0(temp_path, var, "/", var, "_", formatC(m, width = 2, flag = "0"), ".nc")
  infile_enso_var <- here::here(paste0("data_noenso/MEI/mei_", formatC(m, width = 2, flag = "0"), "_var.nc"))
  
  outfile_covar <- here::here(paste0("data_noenso/covar/", var, "_", formatC(m, width = 2, flag = "0"), "_covar_mei.nc"))
  
  infile_enso |> 
    cdo_timcovar(infile_var) |> 
    cdo_execute(output = outfile_covar, options = "-L")
  
  outfile_covar |> 
    cdo_div(infile_enso_var) |> 
    cdo_execute(output = outfile_a, options = "-L")
  
})

## Ordenada
## 

message("Ordenada")

purrr::map(1:12, function(m) {
  
  message(m)
  
  outfile_b <- here::here(paste0("data_noenso/b/", var, "_mei_b_", formatC(m, width = 2, flag = "0"), ".nc"))
  
  if (file.exists(outfile_b)) {
    return(outfile_b)
  }
  
  infile_var <- paste0(temp_path, var, "/", var, "_", formatC(m, width = 2, flag = "0"), ".nc")
  
  outfile_var_mean <- here::here(paste0("data_noenso/mean/", var, "_", formatC(m, width = 2, flag = "0"), "_mean.nc"))
  
  infile_var |> 
    cdo_timmean() |> 
    cdo_execute(output = outfile_var_mean, options = "-L")
  
  infile_enso_mean <- here::here(paste0("data_noenso/MEI/mei_", formatC(m, width = 2, flag = "0"), "_mean.nc"))
  infile_a <- here::here(paste0("data_noenso/a/", var, "_mei_a_", formatC(m, width = 2, flag = "0"), ".nc"))
  infile_var_mean <- outfile_var_mean
  
  infile_enso_mean |> 
    cdo_mul(infile_a) |> 
    cdo_sub(ifile1 = infile_var_mean) |> 
    cdo_execute(output = outfile_b, options = "-L")
  
})

## Subtract signal

message("Substract ENSO")

purrr::map(1:12, function(m) {
  
  message(m)
  
  outfile <-  paste0("/g/data/w40/pc2687/ve/data_noenso/anomaly/", var, "_", formatC(m, width = 2, flag = "0"), "_anomaly_mei.nc")
  dir.create(dirname(outfile), showWarnings = FALSE, recursive = TRUE)
  
  if (file.exists(outfile)) {
    return(outfile)
  }
  
  infile_var <- paste0(temp_path, var, "/", var, "_", formatC(m, width = 2, flag = "0"), ".nc")
  infile_a <- here::here(paste0("data_noenso/a/", var, "_mei_a_", formatC(m, width = 2, flag = "0"), ".nc"))
  infile_b <- here::here(paste0("data_noenso/b/", var, "_mei_b_", formatC(m, width = 2, flag = "0"), ".nc"))
  infile_enso <- here::here(paste0("data_noenso/MEI/mei_", formatC(m, width = 2, flag = "0"), "_enlarged.nc"))
  
  enso_effect <- cdo_mul(infile_a, infile_enso) |>
    cdo_add(infile_b)
  
  enso_effect_file <- enso_effect |>
    cdo_execute(options = "-L")
  
  cdo_sub(infile_var, enso_effect_file) |>
    cdo_execute(options = "-L", output = outfile)
  
})
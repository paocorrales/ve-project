# Help functions

# Group so2 daily emisions into eruptions
#
# time time series
# threshold gap between eruptions in days

group_eruptions <- function(time, threshold = 5) {
  dt <- c(Inf, diff(time))
  dt <- dplyr::if_else(dt > threshold, lubridate::as_date(time), NA)
  data.table::nafill(dt, type = "locf")
}

# Calculate base temperature anomaly for a eruption date
#
# temperature_serie dt with time and t2m_a (temperature anomaly)
# ini_dates eruption date vector
# period lengh of the period to use to calculate the base temperature
# percentiles logical t base for percentiles?
# p char, which percentile if percentiles = TRUE
#
# Returns: a vector of lengh ini_dates

calculate_tbase <- function(temperature_serie, ini_date, period = 12, percentiles = FALSE, p = "p1") {
  
  if(percentiles) {
    
    start_period <- lubridate::as_datetime(ini_date) - months(period)
    
    return(as.numeric(temperature_serie[time %between% c(start_period, ini_date) & percentile == p, 
                                        .(base_t = mean(t2m_a))]))
  } else {
    
    start_period <- lubridate::as_datetime(ini_date) - months(period)
    
    return(as.numeric(temperature_serie[time %between% c(start_period, ini_date), 
                                        .(base_t = mean(t2m_a))]))
  }
  
}

# Get temperature time series for - n years and + n years around the eruption
# FIX: Assumes that the data in in a data.table called global_mean
#
# ini_date date of the eruption
# before years before eruption
# after years after eruption
# percentiles logical t base for percentiles?
# p char, which percentile if percentiles = TRUE
# 
# Returns: a list with time and temperature anomaly, compatible with data.table

get_series <- function(t2_mean, ini_date, before = 1, after = 3, percentiles = FALSE, p = "p1") {
  
  start_time <- ini_date - years(before)
  end_time <- ini_date + years(after)
  
  if (percentiles) {
    temp <- t2_mean[time %between% c(start_time, end_time) & percentile == p] 
    
  } else {
    
    temp <- t2_mean[time %between% c(start_time, end_time)]   
  }
  
  list(time = temp$time,
       t2m_a = temp$t2m_a)
  
}


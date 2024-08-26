#! /bin/bash

# Calculates daily mean from hourly ERA5 data

module load cdo

PATH_IN=/g/data/rt52/era5/single-levels/reanalysis/2t/
PATH_OUT=/scratch/w40/pc2687/daily_means/2t/

for year in {2021..2023};
do
	
	cd $PATH_IN/$year
	files=`echo ls  $PATH_IN/$year/*`
        
	for file in $files;
        do
                echo "Starting..." $(basename "$file") 
		FILE_OUT=${PATH_OUT}/daily_$(basename "$file")
                cdo -daymean $file $FILE_OUT &
	done
	wait
done


cd /scratch/w40/pc2687/

# Remove long term trend

## Calculates a and b from the complete time series
cdo -L -trend -mergetime /scratch/w40/pc2687/daily_means/2t/daily_2t_era5_oper_sfc_* a_2t_daily.nc b_2t_daily.nc

cdo -b F64 -L -mergetime daily_means/2t/daily_2t_era5_oper_sfc_* /scratch/w40/pc2687/2t_daily_all.nc

## Remove trend
cdo -b F64 -L -subtrend /scratch/w40/pc2687/2t_daily_all.nc afile.nc bfile.nc 2t_daily_detrended.nc

# Remove seasonal cycle

cdo -L -b F64 -ydaysub 2t_daily_detrended.nc -ydaymean 2t_daily_detrended.nc 2t_daily_deseasoned.nc

# Calculates percentiles and comparison

## Calculates min and max necesary for the percentile calcualtion
cdo -L -b F64 timmin 2t_daily_deseasoned.nc 2t_min.nc
cdo -L -b F64 timmax 2t_daily_deseasoned.nc 2t_max.nc

## percentile

percentiles='1 5 95 99'

for p in $percentiles;
do

  echo 'Calculating percentile '$p
  cdo -L -b F64 timpctl,$p 2t_daily_deseasoned.nc 2t_min.nc 2t_max.nc 2t_p${p}.nc

done



percentiles='95 99'

for p in $percentiles;
do

  ## comparison
  echo 'Comparing for percentile '$p
  cdo -L -F64 -gt 2t_daily_deseasoned.nc 2t_p${p}.nc 2t_gt_p${p}.nc

  ## If 0 (value bellow percentile), then NA
  echo 'NAs for percentile '$p
  cdo -setctomiss,0 2t_gt_p${p}.nc 2t_gt_p${p}_na.nc

done

percentiles='1 5'

for p in $percentiles;
do

  ## comparison
  echo 'Comparing for percentile '$p
  cdo -L -F64 -lt 2t_daily_deseasoned.nc 2t_p${p}.nc 2t_lt_p${p}.nc

  ## If 0 (value bellow percentile), then NA
  echo 'NAs for percentile '$p
  cdo -setctomiss,0 2t_lt_p${p}.nc 2t_lt_p${p}_na.nc

done
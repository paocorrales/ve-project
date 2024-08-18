#! /bin/bash

# Compares variable with p95

module load cdo

n=5
PATH_IN1=/scratch/w40/pc2687/daily_means/2t/
PATH_IN2=/scratch/w40/pc2687/percentiles/2t/${n}p/
PATH_OUT=/scratch/w40/pc2687/gt_p95/2t/${n}p/

mkdir -p $PATH_OUT

file_list=`ls $PATH_IN1/daily_2t_era5_oper_sfc_*`

# Merge percentiles by month

for month in  $(seq -f "%02g" 1 12);
	do
	  echo $month
	  
	  files_p=$PATH_IN2/${n}p_2t_${month}*
    
    cdo -L -b F64 -mergetime [ $files_p ] $PATH_IN2/${month}.nc
    
done



for year in {1970..2020};
do
	echo "Starting..." $year
	
	for month in  $(seq -f "%02g" 1 12);
	do
	  echo $month
	  
	  file_d=`ls $PATH_IN1/daily_2t_era5_oper_sfc_${year}${month}*`
    
    FILE_OUT=${PATH_OUT}/daily_2t_gt_p${n}_${year}${month}.nc
    
    cdo -L -b F64 -gt $file_d $PATH_IN2/${month}.nc $FILE_OUT &
    
	done
	wait
done

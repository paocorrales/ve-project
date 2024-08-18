#! /bin/bash

# Merge files by month

module load cdo

PATH_IN=/scratch/w40/pc2687/daily_means/2t/
PATH_OUT=/scratch/w40/pc2687/by_month/2t/

for m in $(seq -f "%02g" 1 12);
do
	file_list=`ls $PATH_IN/daily_2t_era5_oper_sfc_*${m}01-*`
	file_out=${PATH_OUT}/daily_2t_era5_oper_sfc_${m}.nc
	echo $file_list
	echo $file_out
	cdo -b F64 -mergetime $file_list $file_out
done


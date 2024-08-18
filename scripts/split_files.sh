#! /bin/bash

# Split monthly file into dayly files

module load cdo

PATH_IN=/scratch/w40/pc2687/by_month/2t/
PATH_OUT=/scratch/w40/pc2687/by_day/2t/

for m in $(seq -f "%02g" 1 12);
do

  cd $PATH_OUT

	file_in=${PATH_IN}/daily_2t_era5_oper_sfc_${m}.nc
	echo $file_in
	cdo splitday $file_in 2t_${m}-

	
done

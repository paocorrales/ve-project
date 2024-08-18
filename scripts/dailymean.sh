#! /bin/bash

# Calculates daily mean from hourly ERA5 data

module load cdo

PATH_IN=/g/data/rt52/era5/single-levels/reanalysis/2t/
PATH_OUT=/scratch/w40/pc2687/daily_means/2t/

for year in {1996..2020};
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


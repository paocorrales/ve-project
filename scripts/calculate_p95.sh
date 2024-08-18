#! /bin/bash

# Calculates the nth percentile for each day

module load cdo
ulimit -s unlimited

n=99
PATH_IN=/scratch/w40/pc2687/by_day/2t/
PATH_OUT=/scratch/w40/pc2687/percentiles/2t/${n}p

mkdir -p $PATH_OUT

file_list=`ls $PATH_IN/*`

for file in $file_list;
do
  echo $file
  cdo -L ydaypctl,$n $file -ydaymin $file -ydaymax $file ${PATH_OUT}/${n}p_$(basename "$file")

	
done

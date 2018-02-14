#!/bin/bash


#*******************************************************
# Read in service list from file targeter.conf
#*******************************************************
scanlist=()
for line in $(eval cat ./targeter.conf);
do
	scan=()
	scan+=($(echo $line | cut -d"=" -f1));
	#scanlist+=" "
	scan+=($(echo $line | cut -d"=" -f2));	
	scanlist+=($scan)
done

#echo ${scanlist[0]};
for scan in "${scanlist[@]}";
do
	echo "${scan[0]} ${scan[1]}";
done

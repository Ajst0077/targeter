#!/bin/bash

#$1 --> First arg; a /24 network. ex: 192.168.0.
#$2 --> Lower bound host [will iterate starting at this IP]
#$3 --> Upper bound host [will stop iterating at this IP]


#*******************************************************
# Read in service list from file targeter.conf
#*******************************************************
servicelist=();
portlist=();
scanlist=();

set -f 
IFS='
'

echo "****** Reading service scan from config file";

for line in $(cat ./target.conf);
do
	echo "Service scan: $line";
	#Each line of config file is formatted: SERVICENAME sp PORT
	#cut -d" " -f1 splits the line on sp and takes the service name
	#cut -d" " -f2 splits the line on sp and takes the port
	#cut -d" " -f3 splits the line on sp and takes the scan type to run
	service=$(echo $line | cut -d" " -f1);
	port=$(echo $line | cut -d" " -f2);
	scan=$(echo $line | cut -d" " -f3);
	
	if [[ $scan == *"U"* ]]
	then
		echo ">>>>>> Note filtered UDP will show as up";
	fi

	servicelist+=($service);
	portlist+=($port);	
	scanlist+=($scan);

done

echo "****** ${#servicelist[@]} services found";

#*******************************************************
# Expand the list of all IPs in the bounds
#*******************************************************

hosts=();
for host in $(seq $2 $3);
do
	hosts+=($1$host);
done

echo "****** ${#hosts[@]} hosts in bounds";

#*******************************************************
# Perform a ping sweep to see what hosts respond to ICMP
#*******************************************************
hostsup=(); #create a blank array - think python list
for host in "${hosts[@]}";
do
	res=$(nmap -sn $host -oG -);
	if [[ $res == *"Status: Up"* ]]
	then
		hostsup+=($host);
	fi
done

echo "****** ${#hostsup[@]} hosts found by ICMP";

#*******************************************************
# Run each scan read in from the .conf file and write 
# the IPs found to an inventory file called targetlist
# w/ sublists sorted by service
#*******************************************************

echo "" > targetlist;

for i in $(seq 0 $(expr ${#servicelist[@]} - 1));
do
	servers=(); #create a blank array - think python list
	for host in "${hostsup[@]}";
	do
		res=$(nmap ${scanlist[$i]} -p ${portlist[$i]} $host -oG -);
		if [[ $res == *"${portlist[$i]}/open"* ]]
		then
			servers+=($host);
		fi
	done

	echo "****** ${#servers[@]} hosts found running ${servicelist[$i]}";
	
	if [[ ! ${#servers[@]} == 0 ]]
	then
		echo "[${servicelist[$i]}]" >> targetlist
		
		for host in "${servers[@]}";
		do
			echo $host >> targetlist
		done
	fi
	echo $'\n' >> targetlist;
done

#*******************************************************
# Write hosts found via ICMP to end of file
# This will be a long list, added at the end for
# readability 
#*******************************************************

echo "[ICMP]" >> targetlist;
for host in "${hostsup[@]}";
do
	echo $host >> targetlist;
done
echo $'\n' >> targetlist;

#*******************************************************
# Write hosts found in range to end of file.
# These hosts may not have responded to pings.
# This will be a long list, so added to added at the end 
# for readability
#*******************************************************

echo "[ALL]" >> targetlist;
for host in "${hosts[@]}";
do
	echo $host >> targetlist;
done
echo $'\n' >> targetlist;
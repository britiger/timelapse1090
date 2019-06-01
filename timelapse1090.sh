#!/bin/bash

trap "kill 0" SIGINT
trap "kill -2 0" SIGTERM
SOURCE=/run/dump1090-fa
INTERVAL=10
HISTORY=12
source /etc/default/timelapse1090

dir=/run/timelapse1090
CS=250
hist=$(($HISTORY*3600/$INTERVAL))
chunks=$(($hist/$CS))


while true
do
	cd $dir
	rm -f *.gz
	rm -f *.json

	cp $SOURCE/receiver.json $dir/receiver.json
	sed -i -e "s/refresh\" : [0-9]*/refresh\" : ${INTERVAL}000/" $dir/receiver.json
	sed -i -e "s/history\" : [0-9]*/history\" : $hist/" $dir/receiver.json

	i=0
	j=0
	while true
	do
		sleep $INTERVAL &
		cd $dir
		cp $SOURCE/aircraft.json history_$((i%$CS)).json


		if [[ $((i%5)) == 0 ]]
		then
			sed -s '$adirty_hack' history_*.json | sed '$d' | gzip > temp.gz
			mv temp.gz chunk_$(($j%$chunks)).gz
		fi

		i=$((i+1))
		if [[ $((i%CS)) == 0 ]]
		then
			j=$((j+1))
			rm history*.json
		fi
		wait
	done
	sleep 5
done &

while true
do
	sleep 1024
done &

wait

exit 0


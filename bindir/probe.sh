#!/bin/bash

## Variables
DATA=${DATA_DIR}
BIN=${BIN_DIR}

CONFIG_FILE="global_config.json"
TARGETS_FILE="targets_list.json"

# Using lock to avoid to start more processes
(
flock -n 200 || echo "Measuring is still in progress, skipping this run."

# Setting probe source name
if [ -z "$PROBE_SOURCE" ]; then
	SOURCE=`hostname -f`
else
	SOURCE=$PROBE_SOURCE
fi

echo "Probe source nane: $SOURCE"

## Loading global configuration
if [ -f "$DATA/$CONFIG_FILE" ]; then
	eval "$(cat $DATA/$CONFIG_FILE | jq -r '.Location | { OriginAS, SourceIP } | to_entries | .[] | .key + "=" + (.value | @sh)')"
	
	DESTINATIONS=''
	cat $DATA/$CONFIG_FILE | jq -r '.Destinations[] | @base64' | while read line ; do
		eval "$(echo $line | base64 --decode | jq -r '{ DestinationURL, DestinationPassword } | to_entries | .[] | .key + "=" + (.value | @sh)')"
		DESTINATIONS="$DESTINATIONS $DestinationPassword@$DestinationURL"
        done	
else
        echo "Global config is missing! Waiting for 5 minutes."
	sleep 300s
        exit 1
fi

## Main loop
if [ -f "$DATA/$TARGETS_FILE" ]; then
	cat $DATA/$TARGETS_FILE | jq -r '.Targets[] | @base64' | shuf | while read line ; do
		eval "$(echo $line | base64 --decode | jq -r '{ IP, DSCP, Custom_comment, Latitude, Longitude} | to_entries | .[] | .key + "=" + (.value | @sh)')"

		echo -n "Processing $IP ... "
		$BIN/metis_mtr.sh -t "$IP" -q "$DSCP" -d "$DESTINATION" -s "$SOURCE" -H "$OriginAS" -A "$SourceIP" -c "$Custom_comment" -o "$Longitude" -l "$Latitude"
		ERR=$?
		if [ $ERR -eq 124 ]; then
			echo "Destination host is not responding; timeout."
		elif [ $ERR -eq 129 ]; then
			echo "Some unexpected situation occurred; KILL signal was sent to mtr."
		elif [ $ERR -ne 0 ]; then
    			echo "Some error occurred during processing of metis mtr wrapper!"
		else
			echo "Ok."
		fi

	done
else
        echo "Probe list doesn't found. Waiting for 5 minutes."
	sleep 300s
	exit 1
fi
exit 0

) 200>/var/lock/mylockfile

# EOF

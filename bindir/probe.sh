#!/bin/bash

## Variables
DATA=${DATA_DIR}
BIN=${BIN_DIR}

CONFIG_FILE="mtr_$CONFIG_FILE"
TARGETS_FILE="mtr_$TARGETS_FILE"

# Using lock to avoid to start more processes
(
flock -n 200 || echo "Measuring is still in progress, skipping this run."

## Loading global configuration
if [ -f "$DATA/$CONFIG_FILE" ]; then
	eval "$(cat $DATA/$CONFIG_FILE | jq -r '.Destination | { DestinationURL, DestinationPassword } | to_entries | .[] | .key + "=" + (.value | @sh)')"
else
        echo "Global config is missing! Waiting for 5 minutes."
        exit 1
fi

## Main loop
if [ -f "$DATA/$TARGETS_FILE" ]; then
	cat $DATA/$TARGETS_FILE | jq -r '.Targets[] | @base64' | shuf | while read line ; do
		eval "$(echo $line | base64 --decode | jq -r '{ IP, DSCP } | to_entries | .[] | .key + "=" + (.value | @sh)')"

		echo -n "Processing $IP ... "
		$BIN/metis_twmping.sh -t $IP -q $DSCP -d $DestinationURL -a $DestinationPassword -s `hostname -f`
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
	exit 1
fi
exit 0

) 200>/var/lock/mylockfile

# EOF

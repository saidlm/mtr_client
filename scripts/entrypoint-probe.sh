#!/bin/sh

## Variables
DATA=${DATA_DIR}
BIN=${BIN_DIR}

PROBE=$BIN/probe.sh

if [ -f "$PROBE" ]; then
	source $PROBE
	exit 0
else
	echo "Probe script is missing!"
	sleep 30s
	exit 1
fi

# EOF

#!/bin/bash
#
# hostname.sh	Set hostname.
#
# 

. /etc/board/rcS

#generate hostname file
if [ "$1" = "start" ]; then
	echo "Generating /etc/hostname..."
	echo -n > $HOSTNAME_DEST_FILE
	proc_line ${HOSTNAME_KEY} $HOSTNAME_SRC_FILE $HOSTNAME_DEST_FILE
fi


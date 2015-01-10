#!/bin/sh

DEBUG_KEY="debug"
DEBUG_OPT=

help(){
		echo "Usage                 : $0 [$DEBUG_KEY]"
		exit 1
}

if [ $# -eq 1 ]; then
	if [ $1 = $DEBUG_KEY ]; then
		DEBUG_OPT=-x
	else 
		help
	fi
fi

bash $DEBUG_OPT /etc/board/cpu-identify.sh start > /dev/null

if [ $? -eq 0 ]; then
	echo "cat $BOARD_INFO_FILE"
	cat $BOARD_INFO_FILE
fi

exit $?



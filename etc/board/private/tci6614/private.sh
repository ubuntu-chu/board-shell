#!/bin/sh
#
# 板载private脚本   用于执行一些板载私有的一些功能 
# 
#

. /etc/board/private/bootenv-utility.sh


if [ "$1" = "start" ]; then
	echo "Starting special private..."

fi


exit 0


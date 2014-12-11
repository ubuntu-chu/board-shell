#!/bin/sh
#
# 
#
# 
#


if [ "$1" = "start" ]; then
	echo "Mounting app partion..."
	/usr/sbin/mount_app_mtd_partion.sh
fi


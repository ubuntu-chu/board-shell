#!/bin/sh

#check /opt 
cat /proc/mounts|awk '{print $2}'|grep "$APP_MOUNT_POINT" > /dev/null
if [ $? -ne 0 ]; then
	echo "mount -t jffs2 -o sync /dev/mtdblock5 /opt"
	mount -t jffs2 -o sync /dev/mtdblock5 /opt
fi






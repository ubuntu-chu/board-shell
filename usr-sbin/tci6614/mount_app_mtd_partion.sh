#!/bin/sh

#/dev/mtd6 使用 ubi文件系统
#check /opt 
cat /proc/mounts|awk '{print $2}'|grep "$APP_MOUNT_POINT" > /dev/null
if [ $? -ne 0 ]; then
	echo "ubiattach /dev/ubi_ctrl -m 6 -O 2048"
	ubiattach /dev/ubi_ctrl -m 6 -O 2048
	echo "mount -t ubifs -o sync /dev/ubi1_0 /opt"
	mount -t ubifs -o sync /dev/ubi1_0 /opt
fi






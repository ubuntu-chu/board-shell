#!/bin/sh

help(){
	echo "Usage                 : $0 <server_ip> [package_file]"
	echo "Param server_ip       : tftp server_ip"
	echo "Param package_file    : package file to application(optional, default package_file name:$DEF_PACKAGE_FILE)"
	exit 1
}

killapp(){
	if [ -x vendor-sys-proc ]; then
		vendor-sys-proc stop
	fi

	sleep 2
}

DEF_PACKAGE_FILE=V2642.tar.gz
PACKAGE_FILE=$DEF_PACKAGE_FILE
DEL_PACKAGE_FILE=1

if [ $# -lt 1 -o $# -gt 2 ]; then
	help
fi

if [ $# -eq 2 ]; then
	PACKAGE_FILE=$2
fi

#check /opt 
cat /proc/mounts|awk '{print $2}'|grep "$APP_MOUNT_POINT" > /dev/null
if [ $? -ne 0 ]; then
	echo "app partion do not mounte to $APP_MOUNT_POINT, now run mount_app_mtd_partion.sh to mount"
	mount_app_mtd_partion.sh
	if [ $? -ne 0 ]; then
		echo "mount app partion fail! please check what happened!"
		exit 3
	fi
fi


cd $FLASH_DIR
echo "now we are in dir:$FLASH_DIR"
echo "package file     :$PACKAGE_FILE"

TFTP_SERVER_IP=$1

if [ ! -r $PACKAGE_FILE ]; then
	echo "package_file<$PACKAGE_FILE> can not find in $FLASH_DIR! use tftp to get it!"
	echo "tftp -g -r $PACKAGE_FILE $TFTP_SERVER_IP"
	tftp -g -r $PACKAGE_FILE $TFTP_SERVER_IP
	if [ $? -ne 0 ]; then
		echo "tftp download file<$PACKAGE_FILE> from server<$TFTP_SERVER_IP> error!"
		rm -rf $PACKAGE_FILE
		exit 2
	fi
fi

killapp

echo "rm -rf $APP_MOUNT_POINT/*"
rm -rf $APP_MOUNT_POINT/*

tar zxvf $PACKAGE_FILE -C /

if [ $? -eq 0 ]; then
	if [ $DEL_PACKAGE_FILE -eq 1 ]; then
		echo "rm -rf $PACKAGE_FILE"
		rm -rf $PACKAGE_FILE
	fi
fi




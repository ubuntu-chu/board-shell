#!/bin/sh

help(){
	echo "Usage                 : $0 <server_ip> [flash_file]"
	echo "Param server_ip       : tftp server_ip"
	echo "Param flash_file      : flash file to mtd partion(optional, default flash_file name:$DEF_FLASH_FILE)"
	exit 1
}

killapp(){
	vendor-sys-proc stop

	sleep 2
}

remove_flashfile()
{
	if [ $DEL_FLASH_FILE -eq 1 ]; then
		echo "rm -rf $FLASH_FILE"
		rm -rf $FLASH_FILE
	fi
}

DEF_FLASH_FILE=itl-app.img
FLASH_FILE=$DEF_FLASH_FILE
DEL_FLASH_FILE=1
if [ -z $APP_MOUNT_POINT ]; then
	FLASH_MTD_PARTION_NAME=app
else
	FLASH_MTD_PARTION_NAME=$APP_PARTION_NAME
fi

if [ $# -lt 1 -o $# -gt 2 ]; then
	help
fi

if [ $# -eq 2 ]; then
	FLASH_FILE=$2
fi

cd $FLASH_DIR
echo "now we are in flash dir:$FLASH_DIR"
echo "flash file             :$FLASH_FILE"
echo "flash mtd partion      :$FLASH_MTD_PARTION_NAME"

TFTP_SERVER_IP=$1

if [ ! -r $FLASH_FILE ]; then
	echo "flash_file<$FLASH_FILE> can not find in $FLASH_DIR! use tftp to get it!"
	echo "tftp -g -r $FLASH_FILE $TFTP_SERVER_IP"
	tftp -g -r $FLASH_FILE $TFTP_SERVER_IP
	if [ $? -ne 0 ]; then
		echo "tftp download file<$FLASH_FILE> from server<$TFTP_SERVER_IP> error!"
		rm -rf $FLASH_FILE
		exit 2
	fi
fi

which file > /dev/null
if [ $? -eq 0 ]; then

ftype=`file "$FLASH_FILE"`

case "$ftype" in
	*"HIT archive data"*)
		echo "$ftype"
		;;

	*) 
		echo "$ftype:invalid compressed format! please check!"
		remove_flashfile
		exit 3
		;;
esac
fi

killapp

#check /opt 
cat /proc/mounts|awk '{print $2}'|grep "$APP_MOUNT_POINT" > /dev/null
if [ $? -eq 0 ]; then
	echo "app mounte to $APP_MOUNT_POINT, now umount $APP_MOUNT_POINT first"
	umount_app_mtd_partion.sh
	if [ $? -ne 0 ]; then
		echo "umount_app_mtd_partion failed! please check your app"
		exit 5
	fi
else
	#若app分区损坏 则强制进行卸载操作
	umount_app_mtd_partion.sh
fi

partion_flash.sh $FLASH_MTD_PARTION_NAME $FLASH_FILE

if [ $? -eq 0 ]; then
	remove_flashfile
fi




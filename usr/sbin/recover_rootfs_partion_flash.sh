#!/bin/sh

help(){
	echo "Usage                 : $0 <server_ip> [flash_file]"
	echo "Param server_ip       : tftp server_ip"
	echo "Param flash_file      : flash file to mtd partion(optional, default flash_file name:$DEF_FLASH_FILE)"
	exit 1
}

remove_flashfile()
{
	if [ $DEL_FLASH_FILE -eq 1 ]; then
		echo "rm -rf $FLASH_FILE"
		rm -rf $FLASH_FILE
	fi
}

DEF_FLASH_FILE=itl-rootfs.img
FLASH_FILE=$DEF_FLASH_FILE
DEL_FLASH_FILE=1
#分区在内核中的名字 用于删除 烧写分区
FLASH_PARTION_NAME="rootfs-recover"
#分区挂载的名字 用于判断分区是否已经挂载    
#大部分情况下两个名字相同 若使用ubi文件系统 则两者不同
FLASH_PARTION_MOUNT_NAME=$FLASH_PARTION_NAME

if [ $# -lt 1 -o $# -gt 2 ]; then
	help
fi

if [ $# -eq 2 ]; then
	FLASH_FILE=$2
fi

#检查rootfs是否已经挂载  
cat /proc/mounts|awk '{print $1}'|grep "$FLASH_PARTION_MOUNT_NAME" > /dev/null
if [ $? -eq 0 ]; then
	echo "$FLASH_PARTION_MOUNT_NAME mounted, can not flash mtd partion<$FLASH_PARTION_NAME>"
	exit 3
fi

cd $FLASH_DIR
echo "now we are in flash dir:$FLASH_DIR"
echo "flash file             :$FLASH_FILE"
echo "flash mtd partion      :$FLASH_PARTION_NAME"

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
	*"Linux jffs2 filesystem"*|*"HIT archive data"*)
		echo "$ftype"
		;;

	*) 
		echo "$ftype:invalid compressed format! please check!"
		remove_flashfile
		exit 3
		;;
esac
fi

partion_flash.sh $FLASH_PARTION_NAME $FLASH_FILE

if [ $? -eq 0 ]; then
	remove_flashfile
fi




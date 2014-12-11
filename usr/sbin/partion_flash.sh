#!/bin/sh

. /usr/sbin/partion_utility.sh

help(){
	echo "Usage                 : $0 <mtd_partion_name> <flash_file>"
	echo "Param mtd_partion_name: partion_name in (cat /proc/mtd)"
	echo "Param flash_file      : flash file to mtd partion"
	exit 1
}

echo "you can get mtd partion name by (cat /proc/mtd)"

if [ $# -ne 2 ]; then
	help
fi

if [ ! -r $2 ]; then
	echo "flash_file<$2> can not read!"
	exit 2
fi

RECOVER_MTD_PART_NAME=$1
if [ -z $KERNEL_PARTION_NAME ]; then
	FLASH_KERNEL_PARTION_NAME=kernel
else
	FLASH_KERNEL_PARTION_NAME=$KERNEL_PARTION_NAME
fi

partion_find $RECOVER_MTD_PART_NAME

if [ $? -ne 0 ]; then
	exit 3
fi

echo "flash_eraseall $PARTION_DEV_FILE"
flash_eraseall $PARTION_DEV_FILE

case "$RECOVER_MTD_PART_NAME" in
	"$FLASH_KERNEL_PARTION_NAME"|"$ROOTFS_PARTION_NAME")
		echo "nandwrite -p $PARTION_DEV_FILE $2"
		nandwrite -p $PARTION_DEV_FILE $2
		;;

	*)
		echo "flashcp -v $2 $PARTION_DEV_FILE"
		flashcp -v $2 $PARTION_DEV_FILE
		;;
esac

RT=$?
if [ $RT -eq 0 ]; then
	echo "mtd partion<$RECOVER_MTD_PART_NAME> flash finish, you can press <reboot> to reboot now!"
else
	echo "flash write failed! please check what happened!"
fi

exit $RT



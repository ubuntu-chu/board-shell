#!/bin/sh

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
MTD_PART_INDEX=0
MTD_PART_FIND=0

while true
do
	if [ -c /dev/mtd$MTD_PART_INDEX ]; then
		MTD_NAME=`mtdinfo /dev/mtd$MTD_PART_INDEX|awk '$1=="Name:"{print}'|awk '{print $2}'`
		if [ $MTD_NAME = $RECOVER_MTD_PART_NAME ]; then
			MTD_PART_FIND=1
			break
		else
			let "MTD_PART_INDEX=MTD_PART_INDEX+1"
		fi
	else 
		break
	fi

done

if [ $MTD_PART_FIND -ne 1 ]; then
	echo "mtd partion<$RECOVER_MTD_PART_NAME> can not find!"
	exit 3
fi

echo "flash_eraseall /dev/mtd$MTD_PART_INDEX"
flash_eraseall /dev/mtd$MTD_PART_INDEX

echo "flashcp -v $2 /dev/mtd$MTD_PART_INDEX"
flashcp -v $2 /dev/mtd$MTD_PART_INDEX

echo "mtd partion<$RECOVER_MTD_PART_NAME> flash finish, you can press <reboot> to reboot now!"





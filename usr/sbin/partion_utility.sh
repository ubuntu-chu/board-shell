#!/bin/sh

PARTION_DEV_FILE=
PARTION_DEV_BLOCK_FILE=
MTD_PART_INDEX=

partion_find()
{
	MTD_PART_INDEX=0
	MTD_PART_FIND=0

	while true
	do
		if [ -c /dev/mtd$MTD_PART_INDEX ]; then
			MTD_NAME=`mtdinfo /dev/mtd$MTD_PART_INDEX|awk '$1=="Name:"{print}'|awk '{print $2}'`
			if [ $MTD_NAME = $1 ]; then
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
		echo "mtd partion<$1> can not find!"
		return 1
	fi
	PARTION_DEV_FILE="/dev/mtd$MTD_PART_INDEX"
	PARTION_DEV_BLOCK_FILE="/dev/mtdblock$MTD_PART_INDEX"

	return 0
}


execute_cmd()
{
	echo ""
	echo "-------------------------------------------------------------"
	echo ""
	echo "$@"
	echo ""
	echo "-------------------------------------------------------------"
	echo ""

	$@
	if [ $? -ne 0 ];then
		echo "execute $@ failed! please check what happened!"
		exit 1
	fi
}

boardinfo_define_copy()
{
	partion_find "$1"
	if [ $? -eq 0 ]; then
		mount_point="/mnt/src"
		boardinfo_define_file="/etc/board/boardinfo.define"
		cat /proc/mounts|awk '{print $2}'|grep "$mount_point" > /dev/null
		if [ $? -eq 0  ]; then
			echo "$mount_point mount! now umount it!"
			execute_cmd umount $mount_point
		fi
		execute_cmd mount -t jffs2 -o sync $PARTION_DEV_BLOCK_FILE $mount_point
		execute_cmd cp $boardinfo_define_file $mount_point/$boardinfo_define_file
		execute_cmd umount $mount_point
	fi
}




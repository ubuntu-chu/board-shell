#!/bin/sh

PARTION_DEV_FILE=
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

	return 0
}






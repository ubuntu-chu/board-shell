#!/bin/sh

. /usr/sbin/partion_utility.sh

BOOTENV_PARTION_NAME="norflash:uboot-env"

echo "erase flash mtd partion:$BOOTENV_PARTION_NAME"

partion_find $BOOTENV_PARTION_NAME

if [ $? -ne 0 ]; then
	exit 3
fi
echo "flash_eraseall $PARTION_DEV_FILE"
flash_eraseall $PARTION_DEV_FILE

if [ $? -ne 0 ]; then
	echo "partion erase failed!"
	exit 3
fi

exit 0



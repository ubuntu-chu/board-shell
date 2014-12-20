#!/bin/sh

PARTION_DIR=$1
PARTION_NAME=$2
#分区大小 128M
PARTION_SIZE=$3

#flash 器件信息
#-s 页大小 2k    
FLASH_PAGE_SIZE=0x800
#-e 块大小 128k
FLASH_BLOCK_SIZE=0x20000

#-s 页大小 2k    
#-e 块大小 128k
#-p 分区大小 
echo "mkfs.jffs2 -s $FLASH_PAGE_SIZE -e $FLASH_BLOCK_SIZE -p $PARTION_SIZE -d $PARTION_DIR -o $PARTION_NAME"
echo "$SUDO_PASSWD" | sudo -S mkfs.jffs2 -s $FLASH_PAGE_SIZE -e $FLASH_BLOCK_SIZE -p $PARTION_SIZE -d $PARTION_DIR -o $PARTION_NAME

if [ -z ${TFTP_SERVER_DIR} ]; then
	echo "copy abort due to var TFTP_SERVER_DIR = null"
	exit 0
fi

echo "cp $PARTION_NAME ${TFTP_SERVER_DIR}/${ITL_LPC3250_PREFIX}${PARTION_NAME}"
cp $PARTION_NAME ${TFTP_SERVER_DIR}/${ITL_LPC3250_PREFIX}${PARTION_NAME}



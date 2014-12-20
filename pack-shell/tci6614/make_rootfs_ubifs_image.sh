#!/bin/sh

#可通过 ubiattach /dev/ubi_ctrl -m x   (x为mtd分区号)  命令来获取nandflash信息
#nandflash  info
SMALLEST_FLASH_IO_UNIT_SIZE=2048
#逻辑块大小
LEB_SIZE=126976
#物理块大小
PEB_SIZE=128KiB
#子页大小
SUB_PAGE_SIZE=512
#vid-hdr-offset
#VID_HDR_OFFSET=512
VID_HDR_OFFSET=2048


UBI_IMAGE_NAME=rootfs.img
UBINIZE_CFG_FILE=ubinize.cfg.boot

#卷全局变量
VOL_MODE=ubi
VOL_TYPE=dynamic

#BOOT_VOL_ID=0
#BOOT_VOL_IMG_NAME=boot.ubifs.img
#BOOT_VOL_SRC_DIR=boot/
#BOOT_VOL_NAME=boot
##8MiB  8*1024*1024
#BOOT_VOL_SIZE=8388608
#
#RECOVERY_VOL_ID=1
#RECOVERY_VOL_IMG_NAME=recovery.ubifs.img
#RECOVERY_VOL_SRC_DIR=rootfs/
#RECOVERY_VOL_NAME=recovery
##12MiB
#RECOVERY_VOL_SIZE=12582912

ROOTFS_VOL_ID=0
ROOTFS_VOL_IMG_NAME=rootfs.ubifs.img
ROOTFS_VOL_SRC_DIR=rootfs/
ROOTFS_VOL_NAME=rootfs
#60MiB
ROOTFS_VOL_SIZE=52428800
ROOTFS_VOL_FLAGS=autoresize

leb_cnt=0

get_leb_cnt()
{
	echo "leb_cnt = $1 / $LEB_SIZE"
	leb_cnt=`expr $1 / $LEB_SIZE`
}

PARTION_BOARDINFO_FILE=$ROOTFS_VOL_SRC_DIR/etc/board/boardinfo.define
BUILD_TIME_KEY="rootfs_img_build_time="

BUILD_TIME=`date +"%F %T"`
echo "$SUDO_PASSWD" | sudo -S sed -i -e "s/^$BUILD_TIME_KEY.*$/$BUILD_TIME_KEY$BUILD_TIME/g" $PARTION_BOARDINFO_FILE



#get_leb_cnt $BOOT_VOL_SIZE
#echo "mkfs.ubifs -r $BOOT_VOL_SRC_DIR -F -o $BOOT_VOL_IMG_NAME -m $SMALLEST_FLASH_IO_UNIT_SIZE -e $LEB_SIZE -c $leb_cnt"
#mkfs.ubifs -r $BOOT_VOL_SRC_DIR -F -o $BOOT_VOL_IMG_NAME -m $SMALLEST_FLASH_IO_UNIT_SIZE -e $LEB_SIZE -c $leb_cnt

get_leb_cnt $ROOTFS_VOL_SIZE
echo "mkfs.ubifs -r $ROOTFS_VOL_SRC_DIR -F -o $ROOTFS_VOL_IMG_NAME -m $SMALLEST_FLASH_IO_UNIT_SIZE -e $LEB_SIZE -c $leb_cnt"
mkfs.ubifs -r $ROOTFS_VOL_SRC_DIR -F -o $ROOTFS_VOL_IMG_NAME -m $SMALLEST_FLASH_IO_UNIT_SIZE -e $LEB_SIZE -c $leb_cnt

if [ -e $UBI_IMAGE_NAME ]; then
	echo "rm -rf $UBI_IMAGE_NAME"
	rm -rf $UBI_IMAGE_NAME
fi

#生成$UBINIZE_CFG_FILE 文件
echo -n "" > $UBINIZE_CFG_FILE
#echo "[$BOOT_VOL_NAME]" >> $UBINIZE_CFG_FILE
#echo "mode=$VOL_MODE" >> $UBINIZE_CFG_FILE
#echo "image=$BOOT_VOL_IMG_NAME" >> $UBINIZE_CFG_FILE
#echo "vol_type=$VOL_TYPE" >> $UBINIZE_CFG_FILE
#echo "vol_id=$BOOT_VOL_ID" >> $UBINIZE_CFG_FILE
#echo "vol_name=$BOOT_VOL_NAME" >> $UBINIZE_CFG_FILE
#echo "vol_size=$BOOT_VOL_SIZE" >> $UBINIZE_CFG_FILE
#
#echo "[$RECOVERY_VOL_NAME]" >> $UBINIZE_CFG_FILE
#echo "mode=$VOL_MODE" >> $UBINIZE_CFG_FILE
#echo "image=$RECOVERY_VOL_IMG_NAME" >> $UBINIZE_CFG_FILE
#echo "vol_type=$VOL_TYPE" >> $UBINIZE_CFG_FILE
#echo "vol_id=$RECOVERY_VOL_ID" >> $UBINIZE_CFG_FILE
#echo "vol_name=$RECOVERY_VOL_NAME" >> $UBINIZE_CFG_FILE
#echo "vol_size=$RECOVERY_VOL_SIZE" >> $UBINIZE_CFG_FILE

echo "[$ROOTFS_VOL_NAME]" >> $UBINIZE_CFG_FILE
echo "mode=$VOL_MODE" >> $UBINIZE_CFG_FILE
echo "image=$ROOTFS_VOL_IMG_NAME" >> $UBINIZE_CFG_FILE
echo "vol_type=$VOL_TYPE" >> $UBINIZE_CFG_FILE
echo "vol_id=$ROOTFS_VOL_ID" >> $UBINIZE_CFG_FILE
echo "vol_name=$ROOTFS_VOL_NAME" >> $UBINIZE_CFG_FILE
echo "vol_size=$ROOTFS_VOL_SIZE" >> $UBINIZE_CFG_FILE
echo "vol_flags=$ROOTFS_VOL_FLAGS" >> $UBINIZE_CFG_FILE

#echo "ubi partion size: `expr \( $BOOT_VOL_SIZE + $RECOVERY_VOL_SIZE + $ROOTFS_VOL_SIZE \) / 1024 / 1024`MiB"
#echo "ubi volum[$BOOT_VOL_NAME] size: `expr \( $BOOT_VOL_SIZE \) / 1024 / 1024`MiB"
#echo "ubi volum[$RECOVERY_VOL_NAME] size: `expr \( $RECOVERY_VOL_SIZE \) / 1024 / 1024`MiB"
echo "ubi volum[$ROOTFS_VOL_NAME] size: `expr \( $ROOTFS_VOL_SIZE \) / 1024 / 1024`MiB"

echo "ubinize -o $UBI_IMAGE_NAME -m $SMALLEST_FLASH_IO_UNIT_SIZE -p $PEB_SIZE -s $SUB_PAGE_SIZE -O $VID_HDR_OFFSET $UBINIZE_CFG_FILE"

ubinize -o $UBI_IMAGE_NAME -m $SMALLEST_FLASH_IO_UNIT_SIZE -p $PEB_SIZE -s $SUB_PAGE_SIZE -O $VID_HDR_OFFSET $UBINIZE_CFG_FILE


if [ -z ${TFTP_SERVER_DIR} ]; then
	echo "copy abort due to var TFTP_SERVER_DIR = null"
	exit 0
fi

echo "cp $UBI_IMAGE_NAME ${TFTP_SERVER_DIR}/${ITL_TCI6614_PREFIX}${UBI_IMAGE_NAME}"
cp $UBI_IMAGE_NAME ${TFTP_SERVER_DIR}/${ITL_TCI6614_PREFIX}${UBI_IMAGE_NAME}



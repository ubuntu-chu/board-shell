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
VID_HDR_OFFSET=2048

APP_UBI_IMAGE_NAME=$1
UBINIZE_CFG_FILE=ubinize.cfg.app

#卷全局变量
VOL_MODE=ubi
VOL_TYPE=dynamic

APP_VOL_ID=0
APP_VOL_IMG_NAME=app-lte.ubifs.img
APP_VOL_SRC_DIR=app-lte
APP_VOL_NAME=app
#350MiB  for 512MiB nandflash
#APP_VOL_SIZE=367001600
#20MiB   for 128MiB nandflash
#APP_VOL_SIZE=20971520
#120MiB  for 256MiB nandflash
#APP_VOL_SIZE=125829120


APP_VOL_SIZE=$2
APP_VOL_FLAGS=autoresize


leb_cnt=0

get_leb_cnt()
{
	echo "leb_cnt = $1 / $LEB_SIZE"
	leb_cnt=`expr $1 / $LEB_SIZE`
}


get_leb_cnt $APP_VOL_SIZE
echo "mkfs.ubifs -r $APP_VOL_SRC_DIR -F -o $APP_VOL_IMG_NAME -m $SMALLEST_FLASH_IO_UNIT_SIZE -e $LEB_SIZE -c $leb_cnt"
mkfs.ubifs -r $APP_VOL_SRC_DIR -F -o $APP_VOL_IMG_NAME -m $SMALLEST_FLASH_IO_UNIT_SIZE -e $LEB_SIZE -c $leb_cnt

#生成$UBINIZE_CFG_FILE 文件
echo -n "" > $UBINIZE_CFG_FILE
echo "[$APP_VOL_NAME]" >> $UBINIZE_CFG_FILE
echo "mode=$VOL_MODE" >> $UBINIZE_CFG_FILE
echo "image=$APP_VOL_IMG_NAME" >> $UBINIZE_CFG_FILE
echo "vol_type=$VOL_TYPE" >> $UBINIZE_CFG_FILE
echo "vol_id=$APP_VOL_ID" >> $UBINIZE_CFG_FILE
echo "vol_name=$APP_VOL_NAME" >> $UBINIZE_CFG_FILE
echo "vol_size=$APP_VOL_SIZE" >> $UBINIZE_CFG_FILE
echo "vol_flags=$APP_VOL_FLAGS" >> $UBINIZE_CFG_FILE


echo "ubi partion size: `expr \( $APP_VOL_SIZE \) / 1024 / 1024`MiB"
echo "ubi volum[$APP_VOL_NAME] size: `expr \( $APP_VOL_SIZE \) / 1024 / 1024`MiB"

echo "ubinize -o $APP_UBI_IMAGE_NAME -m $SMALLEST_FLASH_IO_UNIT_SIZE -p $PEB_SIZE -s $SUB_PAGE_SIZE -O $VID_HDR_OFFSET $UBINIZE_CFG_FILE"

ubinize -o $APP_UBI_IMAGE_NAME -m $SMALLEST_FLASH_IO_UNIT_SIZE -p $PEB_SIZE -s $SUB_PAGE_SIZE -O $VID_HDR_OFFSET $UBINIZE_CFG_FILE

if [ -z ${TFTP_SERVER_DIR} ]; then
	echo "copy abort due to var TFTP_SERVER_DIR = null"
	exit 0
fi

echo "cp $APP_UBI_IMAGE_NAME ${TFTP_SERVER_DIR}/${ITL_TCI6614_PREFIX}${APP_UBI_IMAGE_NAME}"
cp $APP_UBI_IMAGE_NAME ${TFTP_SERVER_DIR}/${ITL_TCI6614_PREFIX}${APP_UBI_IMAGE_NAME}


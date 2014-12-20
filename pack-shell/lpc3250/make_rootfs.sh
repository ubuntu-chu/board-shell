#!/bin/sh

PARTION_DIR=rootfs/
PARTION_BOARDINFO_FILE=$PARTION_DIR/etc/board/boardinfo.define
BUILD_TIME_KEY="rootfs_img_build_time="
PARTION_NAME=rootfs.img
#分区大小 128M
PARTION_SIZE=0x8000000


#BUILD_TIME=`date +"%F %T"`
#echo "$SUDO_PASSWD" | sudo -S sed -i -e "s/^$BUILD_TIME_KEY.*$/$BUILD_TIME_KEY$BUILD_TIME/g" $PARTION_BOARDINFO_FILE

./make_jffs2.sh $PARTION_DIR $PARTION_NAME $PARTION_SIZE 

PARTION_NAME=rootfs-recover.img
./make_jffs2.sh $PARTION_DIR $PARTION_NAME $PARTION_SIZE 


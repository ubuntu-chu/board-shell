#!/bin/sh

ETC_BOARD_SRC_PATH=/home/chum/work/lte/rootfs-common/usr-sbin/src
TCI6614_ETC_BOARD_DEST_PATH=/home/chum/work/lte/rootfs/usr/sbin
LPC3250_ETC_BOARD_DEST_PATH=/home/chum/work/lte/lpc3250/rootfs/usr/sbin

cd $ETC_BOARD_SRC_PATH

shell_list=`find ./ -maxdepth 1 -name "*.sh"`

for i in $shell_list;
do
	echo "cp $i $TCI6614_ETC_BOARD_DEST_PATH/"
	cp $i $TCI6614_ETC_BOARD_DEST_PATH/
	echo "cp $i $LPC3250_ETC_BOARD_DEST_PATH/"
	cp $i $LPC3250_ETC_BOARD_DEST_PATH/
done

echo "cp $ETC_BOARD_SRC_PATH/tci6614/* $TCI6614_ETC_BOARD_DEST_PATH/"
cp $ETC_BOARD_SRC_PATH/tci6614/* $TCI6614_ETC_BOARD_DEST_PATH/
echo "cp $ETC_BOARD_SRC_PATH/lpc3250/* $LPC3250_ETC_BOARD_DEST_PATH/"
cp $ETC_BOARD_SRC_PATH/lpc3250/* $LPC3250_ETC_BOARD_DEST_PATH/




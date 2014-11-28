#!/bin/sh

ETC_BOARD_SRC_PATH=/home/chum/work/lte/etc-board/src
TCI6614_ETC_BOARD_DEST_PATH=/home/chum/work/lte/rootfs/etc/board
LPC3250_ETC_BOARD_DEST_PATH=/home/chum/work/lte/lpc3250/rootfs/etc/board

cd $ETC_BOARD_SRC_PATH

shell_list=`find ./ -maxdepth 1 -name "*.sh"`
shell_list=$shell_list" profile rcS"

rm -rf $TCI6614_ETC_BOARD_DEST_PATH/*
rm -rf $LPC3250_ETC_BOARD_DEST_PATH/*

for i in $shell_list;
do
	cp $i $TCI6614_ETC_BOARD_DEST_PATH/
	cp $i $LPC3250_ETC_BOARD_DEST_PATH/
done

cp $ETC_BOARD_SRC_PATH/profile $TCI6614_ETC_BOARD_DEST_PATH/
cp $ETC_BOARD_SRC_PATH/profile $LPC3250_ETC_BOARD_DEST_PATH/


cp $ETC_BOARD_SRC_PATH/tci6614/* $TCI6614_ETC_BOARD_DEST_PATH/
cp $ETC_BOARD_SRC_PATH/lpc3250/* $LPC3250_ETC_BOARD_DEST_PATH/




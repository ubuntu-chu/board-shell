#!/bin/sh

ETC_BOARD_SUFFIX="etc/board"
USR_SBIN_SUFFIX="usr/sbin"

rootfs_common_path="/home/chum/work/lte/rootfs-common"
ETC_BOARD_SRC_PATH="$rootfs_common_path/etc-board/"
USR_SBIN_SRC_PATH="$rootfs_common_path/usr-sbin/"

rootfs_update_path="$rootfs_common_path/rootfs_update_lpc3250"
rootfs_update_path_etc_board="$rootfs_update_path/$ETC_BOARD_SUFFIX"
rootfs_update_path_usr_sbin="$rootfs_update_path/$USR_SBIN_SUFFIX"
rootfs_update_tar_name="itl-lpc3250-rootfs-update.tar.gz"

cpu_name_lpc3250=lpc3250
cpu_name_tci6614=tci6614

TCI6614_ROOTFS_DEST_PATH="/home/chum/work/lte/rootfs"
TCI6614_ETC_BOARD_DEST_PATH="$TCI6614_ROOTFS_DEST_PATH/$ETC_BOARD_SUFFIX"
TCI6614_USR_SBIN_DEST_PATH="$TCI6614_ROOTFS_DEST_PATH/$USR_SBIN_SUFFIX"

LPC3250_ROOTFS_DEST_PATH="/home/chum/work/lte/lpc3250/rootfs"
LPC3250_ETC_BOARD_DEST_PATH="$LPC3250_ROOTFS_DEST_PATH/$ETC_BOARD_SUFFIX"
LPC3250_USR_SBIN_DEST_PATH="$LPC3250_ROOTFS_DEST_PATH/$USR_SBIN_SUFFIX"


install_files()
{

	files_list_1=`find $1 -maxdepth 1 -type f`
	files_list_2=`find $1/$2 -maxdepth 1 -type f`
	
	for i in $files_list_1 $files_list_2;
	do
	       #echo "cp $i $3/"
		   cp $i $3/
		   #echo -n ""
	done
}

rm -rf $rootfs_update_path
mkdir -p $rootfs_update_path_etc_board
mkdir -p $rootfs_update_path_usr_sbin

rm -rf $rootfs_update_path_etc_board/*
install_files $ETC_BOARD_SRC_PATH $cpu_name_lpc3250 $rootfs_update_path_etc_board
install_files $USR_SBIN_SRC_PATH $cpu_name_lpc3250 $rootfs_update_path_usr_sbin


rm -rf $LPC3250_ETC_BOARD_DEST_PATH/*
install_files $ETC_BOARD_SRC_PATH $cpu_name_lpc3250 $LPC3250_ETC_BOARD_DEST_PATH
install_files $USR_SBIN_SRC_PATH $cpu_name_lpc3250 $LPC3250_USR_SBIN_DEST_PATH

rm -rf $TCI6614_ETC_BOARD_DEST_PATH/*
install_files $ETC_BOARD_SRC_PATH $cpu_name_tci6614 $TCI6614_ETC_BOARD_DEST_PATH
install_files $USR_SBIN_SRC_PATH $cpu_name_tci6614 $TCI6614_USR_SBIN_DEST_PATH

cd $rootfs_update_path
tar zcf $rootfs_update_tar_name ./*
cd ..
mv $rootfs_update_path/$rootfs_update_tar_name .

if [ -z ${TFTP_SERVER_DIR}  ]; then
	echo "copy abort due to var TFTP_SERVER_DIR = null"
	exit 0
fi

cp $rootfs_update_tar_name ${TFTP_SERVER_DIR}/


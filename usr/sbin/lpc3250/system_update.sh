#!/bin/sh

. /usr/sbin/partion_utility.sh

TFTP_SERVER_IP=192.192.192.201
CCU_KEY="ccu"
RRU_KEY="rru"
APP_PACKAGE=
STEP_0="step0"
STEP_1="step1"
STEP_2="step2"
STEP_3="step3"
STEP_4="step4"
FAST="fast"

DEFAULT_ROOTFS_UPDATE_PACKAGE="itl-lpc3250-rootfs-update.tar.gz"
DEFAULT_ROOTFS_PACKAGE="itl-lpc3250-rootfs.img"
DEFAULT_RECOVER_ROOTFS_PACKAGE="itl-lpc3250-rootfs-recover.img"
DEFAULT_KERNEL_PACKAGE="itl-lpc3250-uImage"
DEFAULT_BOOTLOADER_3IN1_PACKAGE="itl-lpc3250-bootloader-3in1.bin"
DEFAULT_CCU_APP_PACKAGE="itl-lpc3250-app-ccu.tar.gz"
DEFAULT_RRU_APP_PACKAGE="itl-lpc3250-app-rru.tar.gz"

if [ -z $RECOVER_ROOTFS_PARTION_NAME ]; then
	FLASH_RECOVER_ROOTFS_PARTION_NAME="rootfs-recover" 
else
	FLASH_RECOVER_ROOTFS_PARTION_NAME=$RECOVER_ROOTFS_PARTION_NAME
fi

if [ -z $ROOTFS_PARTION_NAME ]; then
	FLASH_ROOTFS_PARTION_NAME="rootfs" 
else
	FLASH_ROOTFS_PARTION_NAME=$ROOTFS_PARTION_NAME
fi

help(){
	echo "Usage                 : $0 <server_ip> <board_class> <step>"
	echo "Param server_ip       : tftp server ip address"
	echo "Param board_class     : <$CCU_KEY|$RRU_KEY>"
	#echo "Param step            : <$STEP_1|$STEP_2|$STEP_3|$STEP_4> $STEP_1-$STEP_3 for rootfs, $STEP_4 only for recover-rootfs"
	echo "Param step            : <$STEP_0|$STEP_1|$STEP_2|$STEP_3|$STEP_4|$FAST> $STEP_0-$STEP_3 for rootfs, $STEP_4 only for recover-rootfs, $FAST will update all except rootfs"
	exit 1
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

if [ $# -ne 3 ]; then
	help
fi

TFTP_SERVER_IP=$1

case $2 in
	$CCU_KEY)
		APP_PACKAGE=$DEFAULT_CCU_APP_PACKAGE
		;;
	$RRU_KEY)
		APP_PACKAGE=$DEFAULT_RRU_APP_PACKAGE
		;;
	*)
		help
		;;
esac

case $3 in
	$STEP_0)

		#第一步
		#将rootfs_update.sh脚本通过winscp工具上传到根文件系统中的  /usr/sbin目录下  并添加执行权限 chmod a+x rootfs_update.sh
		#升级根文件系统  暂时
		execute_cmd rootfs_update.sh $TFTP_SERVER_IP $DEFAULT_ROOTFS_UPDATE_PACKAGE
		;;
	$STEP_1)

		#第一步
		#将rootfs_update.sh脚本通过winscp工具上传到根文件系统中的  /usr/sbin目录下  并添加执行权限 chmod a+x rootfs_update.sh
		#升级根文件系统
		#execute_cmd rootfs_update.sh $TFTP_SERVER_IP $DEFAULT_ROOTFS_UPDATE_PACKAGE
		#升级应用程序包
		execute_cmd app_install_upgrade.sh $TFTP_SERVER_IP $APP_PACKAGE
		#升级内核
		execute_cmd kernel_partion_flash.sh $TFTP_SERVER_IP $DEFAULT_KERNEL_PACKAGE
		#重烧写恢复所用根文件系统  原因在于恢复所用根文件系统所有使用的uboot变量在新的uboot变量中可能已经不存在了 所以导致恢复所用根文件系统无法启动
		#TO DO:恢复所用根文件系统烧写完成后 应将其挂载到目录下 依据当前板载定义配置修改其下的/etc/board/boardinfo.define文件
		execute_cmd recover_rootfs_partion_flash.sh $TFTP_SERVER_IP $DEFAULT_RECOVER_ROOTFS_PACKAGE
		#拷贝boardinfo.define文件
		boardinfo_define_copy  $FLASH_RECOVER_ROOTFS_PARTION_NAME
		#重启，此时使用的环境变量仍然为uboot中存在的老旧的环境变量
		execute_cmd reboot
		;;
	$STEP_2)

		#第二步
		#升级bootloader
		execute_cmd bootloader_partion_flash.sh $TFTP_SERVER_IP $DEFAULT_BOOTLOADER_3IN1_PACKAGE
		#重启 使用新的boot环境变量，并自动保存环境变量
		execute_cmd reboot
		;;

	$STEP_3)

		#第三步
		#重启进入到恢复模式
		execute_cmd recovery_mode_restart.sh
		;;
	$STEP_4)

		#第四步
		#恢复根文件系统中
		#升级根文件系统
		execute_cmd rootfs_partion_flash.sh $TFTP_SERVER_IP $DEFAULT_ROOTFS_PACKAGE
		#拷贝boardinfo.define文件
		boardinfo_define_copy  $FLASH_ROOTFS_PARTION_NAME
		#重启进入到正常模式 此时使用根文件系统
		execute_cmd normal_mode_restart.sh
		;;
	$FAST)
		#升级应用程序包
		execute_cmd app_install_upgrade.sh $TFTP_SERVER_IP $APP_PACKAGE
		#升级内核
		execute_cmd kernel_partion_flash.sh $TFTP_SERVER_IP $DEFAULT_KERNEL_PACKAGE
		#升级bootloader
		execute_cmd bootloader_partion_flash.sh $TFTP_SERVER_IP $DEFAULT_BOOTLOADER_3IN1_PACKAGE
		#重烧写恢复所用根文件系统  原因在于恢复所用根文件系统所有使用的uboot变量在新的uboot变量中可能已经不存在了 所以导致恢复所用根文件系统无法启动
		#TO DO:恢复所用根文件系统烧写完成后 应将其挂载到目录下 依据当前板载定义配置修改其下的/etc/board/boardinfo.define文件
		execute_cmd recover_rootfs_partion_flash.sh $TFTP_SERVER_IP $DEFAULT_RECOVER_ROOTFS_PACKAGE
		#拷贝boardinfo.define文件
		boardinfo_define_copy  $FLASH_RECOVER_ROOTFS_PARTION_NAME
		;;
	*)
		help
		;;
esac





